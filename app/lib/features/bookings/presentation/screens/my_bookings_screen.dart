import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quickslot/core/error/result.dart';
import 'package:quickslot/core/router/app_router.dart';
import 'package:quickslot/features/auth/providers/auth_provider.dart';
import 'package:quickslot/features/bookings/data/repositories/booking_repository.dart';
import 'package:quickslot/features/bookings/domain/entities/booking_entity.dart';
import 'package:quickslot/features/bookings/presentation/providers/booking_provider.dart';

// Sport-specific images — consistent with venue list and detail screens
const _badmintonImages = [
  'https://images.unsplash.com/photo-1637666062717-1c6bcfa4a4df?w=640&q=75&auto=format&fit=crop',
  'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=640&q=75&auto=format&fit=crop',
];
const _turfImages = [
  'https://images.unsplash.com/photo-1431324155629-1a6ddc1dec79?w=640&q=75&auto=format&fit=crop',
  'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=640&q=75&auto=format&fit=crop',
];

String _imageForBooking(BookingEntity b) {
  final list = b.sportType == 'turf' ? _turfImages : _badmintonImages;
  return list[b.venueId % list.length];
}

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authProvider) ?? '';
    final bookingsAsync = ref.watch(userBookingsProvider(userId));
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          HapticFeedback.lightImpact();
          context.go(Routes.venueList);
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('My Bookings'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.go(Routes.venueList);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_outlined, size: 20),
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.invalidate(userBookingsProvider(userId));
              },
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: bookingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorState(
            onRetry: () {
              HapticFeedback.lightImpact();
              ref.invalidate(userBookingsProvider(userId));
            },
          ),
          data: (bookings) => bookings.isEmpty
              ? const _EmptyState()
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  itemCount: bookings.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _BookingCard(
                      booking: bookings[i],
                      onCancel: () {
                        HapticFeedback.mediumImpact();
                        _confirmCancel(context, ref, userId, bookings[i]);
                      },
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    String userId,
    BookingEntity booking,
  ) async {
    final theme = Theme.of(context);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Cancel this booking?', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '${booking.venueName} · ${booking.date} · ${booking.startTime.substring(0, 5)}–${booking.endTime.substring(0, 5)}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context, false);
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      backgroundColor: const Color(0xFFF2F5F2), // light pista tint
                      side: BorderSide(color: theme.dividerTheme.color!),
                      foregroundColor: theme.colorScheme.onSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: const Text('Keep It'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      Navigator.pop(context, true);
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      backgroundColor: theme.colorScheme.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
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
            content: const Text('Booking cancelled.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF2E5C50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      case Failure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
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
    final imageUrl = _imageForBooking(booking);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerTheme.color!),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo strip at top
          SizedBox(
            height: 130,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(color: const Color(0xFFEEEEEB));
                  },
                  errorBuilder: (context, error, stackTrace) {
                    final color = booking.sportType == 'badminton'
                        ? const Color(0xFFE8F0EE)
                        : const Color(0xFFE8ECF0);
                    return Container(
                      color: color,
                      child: Center(
                        child: Text(booking.sportEmoji, style: const TextStyle(fontSize: 40)),
                      ),
                    );
                  },
                ),
                // Dark overlay for text readability
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
                // Venue name and confirmed badge on the photo
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          booking.venueName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E5C50),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'CONFIRMED',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                // Date info
                _InfoCell(
                  icon: Icons.calendar_month_outlined,
                  label: 'Date',
                  value: booking.date,
                  theme: theme,
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: theme.dividerTheme.color,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                ),
                // Time info
                _InfoCell(
                  icon: Icons.schedule_outlined,
                  label: 'Time',
                  value: '${booking.startTime.substring(0, 5)} – ${booking.endTime.substring(0, 5)}',
                  theme: theme,
                ),
                const Spacer(),
                // Cancel button
                GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0EE), // very light warm tint
                      border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.25)),
                      borderRadius: BorderRadius.circular(50), // pill
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({required this.icon, required this.label, required this.value, required this.theme});
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
            const SizedBox(width: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 40,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 24),
            Text('No bookings yet.', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Your upcoming slots will appear here once you make a booking.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
          const Icon(Icons.cloud_off_outlined, size: 40, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Could not load bookings.', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Check your network and try again.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 24),
          OutlinedButton(onPressed: onRetry, child: const Text('Try Again')),
        ],
      ),
    );
  }
}
