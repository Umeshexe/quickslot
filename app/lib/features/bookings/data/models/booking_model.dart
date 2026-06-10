import 'package:quickslot/features/bookings/domain/entities/booking_entity.dart';

class BookingModel extends BookingEntity {
  const BookingModel({
    required super.bookingId,
    required super.slotId,
    required super.venueId,
    required super.venueName,
    required super.sportType,
    required super.location,
    required super.date,
    required super.startTime,
    required super.endTime,
    required super.bookedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      bookingId: json['booking_id'] as int,
      slotId: json['slot_id'] as int,
      venueId: json['venue_id'] as int,
      venueName: json['venue_name'] as String,
      sportType: json['sport_type'] as String,
      location: json['location'] as String,
      date: json['date'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      bookedAt: json['booked_at'] as String,
    );
  }
}
