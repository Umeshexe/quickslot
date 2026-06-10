import 'package:flutter_test/flutter_test.dart';
import 'package:quickslot/core/error/result.dart';
import 'package:quickslot/features/bookings/data/models/booking_model.dart';
import 'package:quickslot/features/bookings/domain/entities/booking_entity.dart';
import 'package:quickslot/features/venues/data/models/slot_model.dart';
import 'package:quickslot/features/venues/domain/entities/slot_entity.dart';

void main() {
  // ── BookingModel.fromJson ────────────────────────────────────────────────
  group('BookingModel.fromJson', () {
    final Map<String, dynamic> rawJson = {
      'booking_id': 5,
      'slot_id': 466,
      'venue_id': 5,
      'venue_name': 'Ace Badminton Club',
      'sport_type': 'badminton',
      'location': 'Jayanagar, Bengaluru',
      // Postgres returns full ISO datetime — we must trim to just the date
      'date': '2026-06-11T00:00:00.000Z',
      'start_time': '07:00:00',
      'end_time': '08:00:00',
      'booked_at': '2026-06-10T17:18:49.426Z',
    };

    test('date trims ISO datetime to YYYY-MM-DD', () {
      final booking = BookingModel.fromJson(rawJson);
      expect(booking.date, '2026-06-11');
    });

    test('startTime and endTime include seconds from API', () {
      final booking = BookingModel.fromJson(rawJson);
      expect(booking.startTime, '07:00:00');
      expect(booking.endTime, '08:00:00');
    });

    test('startTime.substring(0,5) gives HH:mm for display', () {
      final booking = BookingModel.fromJson(rawJson);
      expect(booking.startTime.substring(0, 5), '07:00');
      expect(booking.endTime.substring(0, 5), '08:00');
    });

    test('all fields parsed correctly', () {
      final booking = BookingModel.fromJson(rawJson);
      expect(booking.bookingId, 5);
      expect(booking.slotId, 466);
      expect(booking.venueId, 5);
      expect(booking.venueName, 'Ace Badminton Club');
      expect(booking.sportType, 'badminton');
      expect(booking.location, 'Jayanagar, Bengaluru');
    });
  });

  // ── BookingEntity.sportEmoji ─────────────────────────────────────────────
  group('BookingEntity.sportEmoji', () {
    BookingEntity makeBooking(String sportType) => BookingEntity(
          bookingId: 1,
          slotId: 1,
          venueId: 1,
          venueName: 'Test Venue',
          sportType: sportType,
          location: 'Test',
          date: '2026-06-11',
          startTime: '07:00:00',
          endTime: '08:00:00',
          bookedAt: '2026-06-10T00:00:00.000Z',
        );

    test('badminton returns 🏸', () {
      expect(makeBooking('badminton').sportEmoji, '🏸');
    });

    test('turf returns ⚽', () {
      expect(makeBooking('turf').sportEmoji, '⚽');
    });

    test('unknown type defaults to ⚽', () {
      expect(makeBooking('cricket').sportEmoji, '⚽');
    });
  });

  // ── SlotEntity.isAvailable ───────────────────────────────────────────────
  group('SlotEntity.isAvailable', () {
    SlotEntity makeSlot(String status) => SlotEntity(
          id: 1,
          venueId: 1,
          date: '2026-06-11',
          startTime: '07:00:00',
          endTime: '08:00:00',
          status: status,
        );

    test('available slot returns isAvailable = true', () {
      expect(makeSlot('available').isAvailable, isTrue);
    });

    test('booked slot returns isAvailable = false', () {
      expect(makeSlot('booked').isAvailable, isFalse);
    });
  });

  // ── SlotModel.fromJson ───────────────────────────────────────────────────
  group('SlotModel.fromJson', () {
    test('parses booked slot with bookedBy correctly', () {
      final slot = SlotModel.fromJson({
        'id': 466,
        'venue_id': 5,
        'date': '2026-06-11T00:00:00.000Z',
        'start_time': '07:00:00',
        'end_time': '08:00:00',
        'status': 'booked',
        'booked_by': 'user-001',
      });
      expect(slot.status, 'booked');
      expect(slot.isAvailable, isFalse);
      expect(slot.bookedBy, 'user-001');
    });

    test('parses available slot with null bookedBy', () {
      final slot = SlotModel.fromJson({
        'id': 467,
        'venue_id': 5,
        'date': '2026-06-11T00:00:00.000Z',
        'start_time': '08:00:00',
        'end_time': '09:00:00',
        'status': 'available',
        'booked_by': null,
      });
      expect(slot.isAvailable, isTrue);
      expect(slot.bookedBy, isNull);
    });
  });

  // ── Result type ──────────────────────────────────────────────────────────
  group('Result type', () {
    test('Success carries data', () {
      const result = Success(42);
      expect(result, isA<Success<int>>());
      expect((result as Success).data, 42);
    });

    test('Failure carries message', () {
      const result = Failure<int>('Something broke');
      expect(result, isA<Failure<int>>());
      expect((result as Failure).message, 'Something broke');
    });

    test('Failure with SLOT_TAKEN code', () {
      const result = Failure<int>('Slot taken', code: 'SLOT_TAKEN');
      expect((result as Failure).code, 'SLOT_TAKEN');
    });

    test('switch on Result works correctly', () {
      Result<int> makeResult(bool success) =>
          success ? const Success(1) : const Failure('err');

      final value = switch (makeResult(true)) {
        Success(:final data) => data,
        Failure() => -1,
      };
      expect(value, 1);

      final err = switch (makeResult(false)) {
        Success(:final data) => data,
        Failure(:final message) => message,
      };
      expect(err, 'err');
    });
  });
}
