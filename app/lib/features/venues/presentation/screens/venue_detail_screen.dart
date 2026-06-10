import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:quickslot/core/router/app_router.dart';
import 'package:quickslot/core/theme/app_theme.dart';
import 'package:quickslot/features/venues/domain/entities/slot_entity.dart';
import 'package:quickslot/features/venues/presentation/providers/slot_provider.dart';
import 'package:quickslot/features/venues/presentation/providers/venue_provider.dart';

class VenueDetailScreen extends ConsumerWidget {
  const VenueDetailScreen({super.key, required this.venueId});
  final int venueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venuesAsync = ref.watch(venueListProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final slotsAsync = ref.watch(slotListProvider((venueId: venueId, date: dateStr)));
    final selectedSlotId = ref.watch(selectedSlotProvider);
    final theme = Theme.of(context);

    final venue = venuesAsync.valueOrNull?.where((v) => v.id == venueId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(venue?.name ?? 'Venue'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // venue info header
          if (venue != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Icon(Icons.location_on_rounded,
                      size: 14, color: theme.textTheme.bodyMedium?.color),
                  const SizedBox(width: 4),
                  Text(venue.location, style: theme.textTheme.bodyMedium),
                  const Spacer(),
                  Text(
                    '₹${venue.priceInr}/hr',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),

          // date picker row
          SizedBox(
            height: 72,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (context, i) {
                final date = DateTime.now().add(Duration(days: i));
                final isSelected = DateFormat('yyyy-MM-dd').format(date) == dateStr;
                return _DateChip(
                  date: date,
                  isSelected: isSelected,
                  onTap: () {
                    ref.read(selectedDateProvider.notifier).state = date;
                    ref.read(selectedSlotProvider.notifier).state = null;
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Text('Time slots', style: theme.textTheme.titleMedium),
                const Spacer(),
                _LegendDot(color: AppTheme.slotColor('available'), label: 'Free'),
                const SizedBox(width: 12),
                _LegendDot(color: AppTheme.slotColor('booked'), label: 'Taken'),
              ],
            ),
          ),

          // slot grid
          Expanded(
            child: slotsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 40, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text('Could not load slots', style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(slotListProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (slots) => slots.isEmpty
                  ? Center(
                      child: Text('No slots for this date',
                          style: theme.textTheme.bodyMedium),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.2,
                      ),
                      itemCount: slots.length,
                      itemBuilder: (context, i) {
                        final slot = slots[i];
                        final isSelected = selectedSlotId == slot.id;
                        return _SlotChip(
                          slot: slot,
                          isSelected: isSelected,
                          onTap: slot.isAvailable
                              ? () {
                                  ref.read(selectedSlotProvider.notifier).state =
                                      isSelected ? null : slot.id;
                                }
                              : null,
                        );
                      },
                    ),
            ),
          ),
        ],
      ),

      // book button — only shows when a slot is selected
      bottomNavigationBar: selectedSlotId != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: () {
                    final slots = slotsAsync.valueOrNull ?? [];
                    final slot = slots.firstWhere((s) => s.id == selectedSlotId);
                    context.push(Routes.bookingConfirm, extra: {
                      'slotId': slot.id,
                      'venueName': venue?.name ?? '',
                      'date': slot.date,
                      'startTime': slot.startTime,
                      'endTime': slot.endTime,
                    });
                  },
                  child: const Text('Book this slot'),
                ),
              ),
            )
          : null,
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.date, required this.isSelected, required this.onTap});
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('EEE').format(date),
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.black : theme.textTheme.bodyMedium?.color,
              ),
            ),
            Text(
              DateFormat('d').format(date),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.black : theme.textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({required this.slot, required this.isSelected, this.onTap});
  final SlotEntity slot;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.slotColor(slot.status, isSelected: isSelected);
    final textColor = AppTheme.slotTextColor(slot.status, isSelected: isSelected);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected ? bgColor.withValues(alpha: 0.25) : bgColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? bgColor : bgColor.withValues(alpha: 0.4),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            slot.startTime.substring(0, 5),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color)),
      ],
    );
  }
}
