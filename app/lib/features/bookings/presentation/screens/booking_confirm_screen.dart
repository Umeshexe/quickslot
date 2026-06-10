import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quickslot/core/router/app_router.dart';
import 'package:quickslot/features/auth/providers/auth_provider.dart';
import 'package:quickslot/features/bookings/presentation/providers/booking_provider.dart';
import 'package:quickslot/features/venues/presentation/providers/slot_provider.dart';

class BookingConfirmScreen extends ConsumerWidget {
  const BookingConfirmScreen({
    super.key,
    required this.slotId,
    required this.venueName,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  final int slotId;
  final String venueName;
  final String date;
  final String startTime;
  final String endTime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingState = ref.watch(bookingNotifierProvider);
    final userId = ref.watch(authProvider) ?? '';
    final theme = Theme.of(context);

    ref.listen(bookingNotifierProvider, (prev, next) {
      if (next.status == BookingStatus.success) {
        _showSuccessAndPop(context, ref, userId);
      } else if (next.status == BookingStatus.slotTaken) {
        _showSlotTakenDialog(context, ref);
      } else if (next.status == BookingStatus.failed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? 'Booking failed'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Booking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                border: Border.all(color: theme.dividerTheme.color!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _SummaryRow(label: 'Venue', value: venueName, theme: theme),
                  const Divider(height: 1),
                  _SummaryRow(label: 'Date', value: date, theme: theme),
                  const Divider(height: 1),
                  _SummaryRow(label: 'Time', value: '${startTime.substring(0, 5)} – ${endTime.substring(0, 5)}', theme: theme),
                  const Divider(height: 1),
                  _SummaryRow(label: 'Player', value: userId, theme: theme),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This slot will be reserved under your profile. You can cancel at any time before the match.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: bookingState.status == BookingStatus.loading
                  ? null
                  : () => ref.read(bookingNotifierProvider.notifier).book(userId, slotId),
              child: bookingState.status == BookingStatus.loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Confirm Reservation'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessAndPop(BuildContext context, WidgetRef ref, String userId) {
    ref.read(bookingNotifierProvider.notifier).reset();
    ref.read(selectedSlotProvider.notifier).state = null;
    ref.invalidate(userBookingsProvider(userId));
    
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmed'),
        content: Text('Your slot at $venueName has been successfully booked.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(Routes.venueList);
            },
            child: Text('Home', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(Routes.myBookings);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(100, 40),
            ),
            child: const Text('View Bookings'),
          ),
        ],
      ),
    );
  }

  void _showSlotTakenDialog(BuildContext context, WidgetRef ref) {
    ref.read(bookingNotifierProvider.notifier).reset();
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Slot Unavailable'),
        content: const Text('This slot was just booked by someone else. Please select another time.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Choose Another Slot'),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, required this.theme});
  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
