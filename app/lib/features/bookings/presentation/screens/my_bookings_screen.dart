import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quickslot/core/error/result.dart';
import 'package:quickslot/core/router/app_router.dart';
import 'package:quickslot/features/auth/providers/auth_provider.dart';
import 'package:quickslot/features/bookings/data/repositories/booking_repository.dart';
import 'package:quickslot/features/bookings/domain/entities/booking_entity.dart';
import 'package:quickslot/features/bookings/presentation/providers/booking_provider.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authProvider) ?? '';
    final bookingsAsync = ref.watch(userBookingsProvider(userId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.venueList);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go(Routes.venueList),
          ),
          actions: [
            // refresh
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(userBookingsProvider(userId)),
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: bookingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorState(onRetry: () => ref.invalidate(userBookingsProvider(userId))),
          data: (bookings) => bookings.isEmpty
              ? const _EmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: bookings.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (_, i) => _BookingCard(
                    booking: bookings[i],
                    onCancel: () => _cancelBooking(context, ref, userId, bookings[i]),
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _cancelBooking(
    BuildContext context,
    WidgetRef ref,
    String userId,
    BookingEntity booking,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1E2230),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5C5C).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF5C5C), size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cancel this booking?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFF0F4FF)),
              ),
              const SizedBox(height: 8),
              Text(
                '${booking.venueName}\n${booking.date}  ·  ${booking.startTime.substring(0, 5)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF8B95B0), height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2A2F3E)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Keep it', style: TextStyle(color: Color(0xFFF0F4FF))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5C5C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final repo = ref.read(bookingRepositoryProvider);
    final result = await repo.cancelBooking(userId, booking.bookingId);

    if (!context.mounted) return;

    switch (result) {
      case Success():
        ref.invalidate(userBookingsProvider(userId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Booking cancelled'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      case Failure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFFFF5C5C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
    }
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onCancel});
  final BookingEntity booking;
  final VoidCallback onCancel;

  static const _sportColors = {
    'badminton': Color(0xFF00C896),
    'turf': Color(0xFF4F8EF7),
  };

  @override
  Widget build(BuildContext context) {
    final accentColor = _sportColors[booking.sportType] ?? const Color(0xFF8B5CF6);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2230),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2F3E)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // colored left accent strip
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                child: Row(
                  children: [
                    // sport icon
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Center(
                        child: Text(booking.sportEmoji, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            booking.venueName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF0F4FF),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 11, color: Color(0xFF8B95B0)),
                              const SizedBox(width: 4),
                              Text(
                                booking.date,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF8B95B0)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  size: 11, color: Color(0xFF8B95B0)),
                              const SizedBox(width: 4),
                              Text(
                                '${booking.startTime.substring(0, 5)} – ${booking.endTime.substring(0, 5)}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF8B95B0)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // status chip + cancel
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Confirmed',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: onCancel,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: Color(0xFFFF5C5C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1E2230),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2A2F3E)),
            ),
            child: const Center(
              child: Text('🏸', style: TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No bookings yet',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFF0F4FF)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Go book a slot and it will show up here',
            style: TextStyle(fontSize: 13, color: Color(0xFF8B95B0)),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFF8B95B0)),
          const SizedBox(height: 12),
          const Text('Could not load bookings',
              style: TextStyle(fontSize: 15, color: Color(0xFFF0F4FF), fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
