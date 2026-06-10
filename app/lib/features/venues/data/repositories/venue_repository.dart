import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickslot/core/constants/api_constants.dart';
import 'package:quickslot/core/error/result.dart';
import 'package:quickslot/core/network/dio_client.dart';
import 'package:quickslot/features/venues/data/models/venue_model.dart';
import 'package:quickslot/features/venues/domain/entities/venue_entity.dart';

class VenueRepository {
  VenueRepository(this._dio);
  final Dio _dio;

  Future<Result<List<VenueEntity>>> getVenues() async {
    try {
      final res = await _dio.get(ApiConstants.venues);
      final venues = (res.data as List)
          .map((e) => VenueModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Success(venues);
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to load venues');
    } catch (e) {
      return Failure('Something went wrong');
    }
  }
}

final venueRepositoryProvider = Provider<VenueRepository>(
  (ref) => VenueRepository(ref.read(dioClientProvider)),
);
