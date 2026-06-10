import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:quickslot/core/router/app_router.dart';
import 'package:quickslot/features/venues/domain/entities/slot_entity.dart';
import 'package:quickslot/features/venues/domain/entities/venue_entity.dart';
import 'package:quickslot/features/venues/presentation/providers/slot_provider.dart';
import 'package:quickslot/features/venues/presentation/providers/venue_provider.dart';

// Same sport-specific images as the home screen
const _badmintonImages = [
  'https://images.unsplash.com/photo-1637666062717-1c6bcfa4a4df?w=800&q=75&auto=format&fit=crop',
  'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800&q=75&auto=format&fit=crop',
];
const _turfImages = [
  'https://images.unsplash.com/photo-1431324155629-1a6ddc1dec79?w=800&q=75&auto=format&fit=crop',
  'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=800&q=75&auto=format&fit=crop',
];

String _imageFor(VenueEntity v) {
  final list = v.sportType == 'turf' ? _turfImages : _badmintonImages;
  return list[v.id % list.length];
}

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
    final activeFilter = ref.watch(slotTimeFilterProvider);
    final theme = Theme.of(context);

    final venue = venuesAsync.valueOrNull?.where((v) => v.id == venueId).firstOrNull;
    // Fallback is sport-neutral; once venue loads it uses the correct sport image
    final imageUrl = venue != null
        ? _imageFor(venue)
        : _turfImages[venueId % _turfImages.length];  // reasonable default while loading

    return Scaffold(
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // Hero photo app bar
          SliverAppBar(
            expandedHeight: 260.0,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 1,
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroImage(
                imageUrl: imageUrl,
                sportType: venue?.sportType ?? 'turf',
              ),
              collapseMode: CollapseMode.pin,
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, size: 18),
                  color: Colors.black87,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.pop();
                  },
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Venue header
                if (venue != null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                venue.name,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      venue.location,
                                      style: theme.textTheme.bodyMedium,
                                      maxLines: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${venue.priceInr}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Text(
                              '/ hr',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                ],

                // Date picker section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Text(
                    'Select Date',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
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
                          HapticFeedback.selectionClick();
                          ref.read(selectedDateProvider.notifier).state = date;
                          ref.read(selectedSlotProvider.notifier).state = null;
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Times section header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Available Times',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Row(
                        children: [
                          _LegendDot(color: theme.colorScheme.primary, label: 'Selected'),
                          const SizedBox(width: 12),
                          _LegendDot(
                            color: const Color(0xFFEAEAE6),
                            label: 'Booked',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Time-of-day filter chips
                SizedBox(
                  height: 36,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: activeFilter == null,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref.read(slotTimeFilterProvider.notifier).state = null;
                        },
                      ),
                      const SizedBox(width: 8),
                      for (final f in TimeFilter.values) ...[
                        _FilterChip(
                          label: f.label,
                          isSelected: activeFilter == f,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref.read(slotTimeFilterProvider.notifier).state =
                                activeFilter == f ? null : f;
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),

          // Slots grid
          slotsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Text('Could not load slots.', style: theme.textTheme.bodyMedium),
              ),
            ),
            data: (slots) {
                final filtered = activeFilter == null
                    ? slots
                    : slots.where((s) => activeFilter.matches(s.startTime)).toList();
                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            slots.isEmpty ? 'No slots for this date.' : 'No ${activeFilter?.label ?? ""} slots.',
                            style: theme.textTheme.bodyMedium,
                          ),
                          if (slots.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => ref.read(slotTimeFilterProvider.notifier).state = null,
                              child: const Text('Show all times'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }
                return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.6,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final slot = filtered[i];
                          final isSelected = selectedSlotId == slot.id;
                          return _SlotChip(
                            slot: slot,
                            isSelected: isSelected,
                            onTap: slot.isAvailable
                                ? () {
                                    HapticFeedback.selectionClick();
                                    ref.read(selectedSlotProvider.notifier).state =
                                        isSelected ? null : slot.id;
                                  }
                                : null,
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  );
              },
          ),
        ],
      ),

      // Sticky bottom CTA
      bottomNavigationBar: selectedSlotId != null
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  border: Border(top: BorderSide(color: theme.dividerTheme.color!)),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    final slots = slotsAsync.valueOrNull ?? [];
                    final matched = slots.where((s) => s.id == selectedSlotId).firstOrNull;
                    if (matched == null) return;
                    context.push(Routes.bookingConfirm, extra: {
                      'slotId': matched.id,
                      'venueName': venue?.name ?? '',
                      'date': matched.date,
                      'startTime': matched.startTime,
                      'endTime': matched.endTime,
                    });
                  },
                  child: const Text('Continue to Booking'),
                ),
              ),
            )
          : null,
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.imageUrl, required this.sportType});
  final String imageUrl;
  final String sportType;

  @override
  Widget build(BuildContext context) {
    final fallbackBg = sportType == 'turf'
        ? const Color(0xFFCEE5C8)   // grass green
        : const Color(0xFFBFD9E8);  // court blue
    final fallbackEmoji = sportType == 'turf' ? '⚽' : '🏸';

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(color: const Color(0xFFEEEEEB));
          },
          errorBuilder: (context, error, stackTrace) => Container(
            color: fallbackBg,
            child: Center(
              child: Text(fallbackEmoji, style: const TextStyle(fontSize: 72)),
            ),
          ),
        ),
        // gradient only at very top for back button readability, very subtle
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [Colors.black.withValues(alpha: 0.3), Colors.transparent],
            ),
          ),
        ),
      ],
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
    final isToday = DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerTheme.color!,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isToday ? 'TODAY' : DateFormat('EEE').format(date).toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              DateFormat('d').format(date),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
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
    final theme = Theme.of(context);
    final isAvailable = slot.isAvailable;

    Color bgColor;
    Color borderColor;
    Color textColor;

    if (isSelected) {
      bgColor = theme.colorScheme.primary;
      borderColor = theme.colorScheme.primary;
      textColor = Colors.white;
    } else if (isAvailable) {
      bgColor = Colors.transparent;
      borderColor = theme.dividerTheme.color!;
      textColor = theme.colorScheme.onSurface;
    } else {
      // Clearly dimmed — solid light gray so it reads as unavailable at a glance
      bgColor = const Color(0xFFEAEAE6);
      borderColor = const Color(0xFFDEDED8);
      textColor = const Color(0xFFBBBBB0);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Text(
            slot.startTime.substring(0, 5),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textColor,
              decoration: !isAvailable ? TextDecoration.lineThrough : null,
              decorationColor: textColor,
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
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.isSelected, required this.onTap});
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerTheme.color!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? Colors.white
                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
