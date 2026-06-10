import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickslot/core/error/result.dart';
import 'package:quickslot/features/venues/data/repositories/venue_repository.dart';
import 'package:quickslot/features/venues/domain/entities/venue_entity.dart';

// fetches venues on first watch, caches result
final venueListProvider = FutureProvider<List<VenueEntity>>((ref) async {
  final repo = ref.read(venueRepositoryProvider);
  final result = await repo.getVenues();
  return switch (result) {
    Success(:final data) => data,
    Failure(:final message) => throw Exception(message),
  };
});
