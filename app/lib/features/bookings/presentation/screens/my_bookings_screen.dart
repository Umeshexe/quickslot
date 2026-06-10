import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickslot/core/error/result.dart';
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 40, color: Colors.grey),
              const SizedBox(height: 12),
              Text('Could not load bookings', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(userBookingsProvider(userId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (bookings) => bookings.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bookmark_border_rounded, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('No bookings yet', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Go book a slot!', style: theme.textTheme.bodyMedium),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: bookings.length,
                separatorBuilder: (context, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _BookingCard(
                  booking: bookings[i],
                  onCancel: () => _cancelBooking(context, ref, userId, bookings[i]),
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
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E2230),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel booking?'),
        content: Text(
          '${booking.venueName}\n${booking.date} · ${booking.startTime.substring(0, 5)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Cancel booking',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
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
          const SnackBar(content: Text('Booking cancelled')),
        );
      case Failure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
    }
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onCancel});
  final BookingEntity booking;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(booking.sportEmoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.venueName, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '${booking.date}  ·  ${booking.startTime.substring(0, 5)} – ${booking.endTime.substring(0, 5)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.cancel_outlined, color: theme.colorScheme.error),
            onPressed: onCancel,
            tooltip: 'Cancel',
          ),
        ],
      ),
    );
  }
}
