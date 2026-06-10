class SlotEntity {
  const SlotEntity({
    required this.id,
    required this.venueId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.bookedBy,
  });

  final int id;
  final int venueId;
  final String date;
  final String startTime;
  final String endTime;
  final String status; // 'available' or 'booked'
  final String? bookedBy;

  bool get isAvailable => status == 'available';
}
