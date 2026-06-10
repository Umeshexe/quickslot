import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickslot/core/error/result.dart';
import 'package:quickslot/features/venues/data/repositories/slot_repository.dart';
import 'package:quickslot/features/venues/domain/entities/slot_entity.dart';

// holds the selected date for the venue detail screen
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// holds the selected slot id (for highlight in grid)
final selectedSlotProvider = StateProvider<int?>((ref) => null);

// fetches slots whenever venueId or date changes
final slotListProvider = FutureProvider.family<List<SlotEntity>, ({int venueId, String date})>(
  (ref, args) async {
    final repo = ref.read(slotRepositoryProvider);
    final result = await repo.getSlots(args.venueId, args.date);
    return switch (result) {
      Success(:final data) => data,
      Failure(:final message) => throw Exception(message),
    };
  },
);
