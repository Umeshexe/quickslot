import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickslot/core/error/result.dart';
import 'package:quickslot/features/venues/data/repositories/slot_repository.dart';
import 'package:quickslot/features/venues/domain/entities/slot_entity.dart';

// holds the selected date for the venue detail screen
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// holds the selected slot id (for highlight in grid)
final selectedSlotProvider = StateProvider<int?>((ref) => null);

// Active time-of-day filter: null = show all
final slotTimeFilterProvider = StateProvider<TimeFilter?>((ref) => null);

enum TimeFilter { morning, afternoon, evening }

extension TimeFilterLabel on TimeFilter {
  String get label {
    switch (this) {
      case TimeFilter.morning:
        return '🌅 Morning';
      case TimeFilter.afternoon:
        return '☀️ Afternoon';
      case TimeFilter.evening:
        return '🌙 Evening';
    }
  }

  bool matches(String startTime) {
    final parts = startTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    switch (this) {
      case TimeFilter.morning:
        return hour >= 5 && hour < 12;
      case TimeFilter.afternoon:
        return hour >= 12 && hour < 17;
      case TimeFilter.evening:
        return hour >= 17 || hour < 5;
    }
  }
}

// fetches slots whenever venueId or date changes
final slotListProvider = FutureProvider.family<List<SlotEntity>, ({int venueId, String date})>(
  (ref, args) async {
    final repo = ref.read(slotRepositoryProvider);
    final result = await repo.getSlots(args.venueId, args.date);
    // Auto-poll: invalidate this provider every 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      // Only re-fetch if provider is still alive
      try {
        ref.invalidateSelf();
      } catch (_) {}
    });
    return switch (result) {
      Success(:final data) => data,
      Failure(:final message) => throw Exception(message),
    };
  },
);
