import 'package:quickslot/features/venues/domain/entities/slot_entity.dart';

class SlotModel extends SlotEntity {
  const SlotModel({
    required super.id,
    required super.venueId,
    required super.date,
    required super.startTime,
    required super.endTime,
    required super.status,
    super.bookedBy,
  });

  factory SlotModel.fromJson(Map<String, dynamic> json) {
    return SlotModel(
      id: json['id'] as int,
      venueId: json['venue_id'] as int,
      date: json['date'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      status: json['status'] as String,
      bookedBy: json['booked_by'] as String?,
    );
  }
}
