import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickslot/core/constants/api_constants.dart';
import 'package:quickslot/core/error/result.dart';
import 'package:quickslot/core/network/dio_client.dart';
import 'package:quickslot/features/bookings/data/models/booking_model.dart';
import 'package:quickslot/features/bookings/domain/entities/booking_entity.dart';

class BookingRepository {
  BookingRepository(this._dio);
  final Dio _dio;

  Future<Result<int>> createBooking(String userId, int slotId) async {
    try {
      final res = await _dio.post(
        ApiConstants.bookings,
        data: {'slot_id': slotId},
        options: Options(extra: {'userId': userId}),
      );
      return Success(res.data['id'] as int);
    } on DioException catch (e) {
      // 409 = slot already taken by someone else
      if (e.response?.statusCode == 409) {
        return const Failure('This slot was just taken by someone else', code: 'SLOT_TAKEN');
      }
      return Failure(e.message ?? 'Booking failed');
    } catch (e) {
      return Failure('Something went wrong');
    }
  }

  Future<Result<void>> cancelBooking(String userId, int bookingId) async {
    try {
      await _dio.delete(
        ApiConstants.bookingById(bookingId),
        options: Options(extra: {'userId': userId}),
      );
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.message ?? 'Cancellation failed');
    } catch (e) {
      return Failure('Something went wrong');
    }
  }

  Future<Result<List<BookingEntity>>> getUserBookings(String userId) async {
    try {
      final res = await _dio.get(ApiConstants.userBookings(userId));
      final bookings = (res.data as List)
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Success(bookings);
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to load bookings');
    } catch (e) {
      return Failure('Something went wrong');
    }
  }
}

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => BookingRepository(ref.read(dioClientProvider)),
);
