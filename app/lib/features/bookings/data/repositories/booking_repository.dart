import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickslot/core/constants/api_constants.dart';
import 'package:quickslot/core/error/result.dart';
import 'package:quickslot/core/network/dio_client.dart';
import 'package:quickslot/features/bookings/data/models/booking_model.dart';
import 'package:quickslot/features/bookings/domain/entities/booking_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists bookings locally so My Bookings works even when offline.
class BookingRepository {
  BookingRepository(this._dio);
  final Dio _dio;

  static String _cacheKey(String userId) => 'bookings_cache_$userId';

  // ── helpers ──────────────────────────────────────────────────────────────

  Future<void> _writeCache(String userId, List<BookingEntity> bookings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = bookings
          .map((b) => {
                'booking_id': b.bookingId,
                'slot_id': b.slotId,
                'venue_id': b.venueId,
                'venue_name': b.venueName,
                'sport_type': b.sportType,
                'location': b.location,
                'date': b.date,
                'start_time': b.startTime,
                'end_time': b.endTime,
                'booked_at': b.bookedAt,
              })
          .toList();
      await prefs.setString(_cacheKey(userId), jsonEncode(json));
    } catch (_) {}
  }

  Future<List<BookingEntity>?> _readCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey(userId));
      if (raw == null) return null;
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  // ── public API ────────────────────────────────────────────────────────────

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

  /// Fetches bookings from the network, caches them locally.
  /// If offline, falls back to the last cached result.
  Future<Result<List<BookingEntity>>> getUserBookings(String userId) async {
    try {
      final res = await _dio.get(ApiConstants.userBookings(userId));
      final bookings = (res.data as List)
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList();
      // Persist for offline read
      await _writeCache(userId, bookings);
      return Success(bookings);
    } on DioException catch (e) {
      // Network error — serve from cache if available
      final cached = await _readCache(userId);
      if (cached != null) return Success(cached);
      return Failure(e.message ?? 'Failed to load bookings');
    } catch (e) {
      final cached = await _readCache(userId);
      if (cached != null) return Success(cached);
      return Failure('Something went wrong');
    }
  }
}

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => BookingRepository(ref.read(dioClientProvider)),
);
