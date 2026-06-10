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

    // listen for state changes to show feedback
    ref.listen(bookingNotifierProvider, (prev, next) {
      if (next.status == BookingStatus.success) {
        _showSuccessAndPop(context, ref);
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
      appBar: AppBar(title: const Text('Confirm Booking')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // booking summary card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Booking Summary', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 20),
                  _Row(label: 'Venue', value: venueName),
                  const SizedBox(height: 12),
                  _Row(label: 'Date', value: date),
                  const SizedBox(height: 12),
                  _Row(label: 'Time', value: '${startTime.substring(0, 5)} – ${endTime.substring(0, 5)}'),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Slot is held until confirmed. Tap Book to reserve it.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: bookingState.status == BookingStatus.loading
                  ? null
                  : () => ref
                      .read(bookingNotifierProvider.notifier)
                      .book(userId, slotId),
              child: bookingState.status == BookingStatus.loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : const Text('Confirm Booking'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessAndPop(BuildContext context, WidgetRef ref) {
    ref.read(bookingNotifierProvider.notifier).reset();
    ref.read(selectedSlotProvider.notifier).state = null;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E2230),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Icon(Icons.check_circle_rounded, color: Color(0xFF00C896), size: 56),
            const SizedBox(height: 16),
            const Text('Booking Confirmed!',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            Text('$venueName\n$date · ${startTime.substring(0, 5)}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF8B95B0))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go(Routes.venueList);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSlotTakenDialog(BuildContext context, WidgetRef ref) {
    ref.read(bookingNotifierProvider.notifier).reset();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E2230),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Slot just taken'),
        content: const Text(
          'Someone else booked this slot a moment ago. Please go back and pick another time.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop(); // go back to slot grid
            },
            child: const Text('Pick another slot'),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(value, style: theme.textTheme.titleMedium),
      ],
    );
  }
}
