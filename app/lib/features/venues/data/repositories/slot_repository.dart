import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickslot/core/constants/api_constants.dart';
import 'package:quickslot/core/error/result.dart';
import 'package:quickslot/core/network/dio_client.dart';
import 'package:quickslot/features/venues/data/models/slot_model.dart';
import 'package:quickslot/features/venues/domain/entities/slot_entity.dart';

class SlotRepository {
  SlotRepository(this._dio);
  final Dio _dio;

  Future<Result<List<SlotEntity>>> getSlots(int venueId, String date) async {
    try {
      final res = await _dio.get(
        ApiConstants.venueSlots(venueId),
        queryParameters: {'date': date},
      );
      final slots = (res.data as List)
          .map((e) => SlotModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Success(slots);
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to load slots');
    } catch (e) {
      return Failure('Something went wrong');
    }
  }
}

final slotRepositoryProvider = Provider<SlotRepository>(
  (ref) => SlotRepository(ref.read(dioClientProvider)),
);
