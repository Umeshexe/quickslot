class BookingEntity {
  const BookingEntity({
    required this.bookingId,
    required this.slotId,
    required this.venueId,
    required this.venueName,
    required this.sportType,
    required this.location,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.bookedAt,
  });

  final int bookingId;
  final int slotId;
  final int venueId;
  final String venueName;
  final String sportType;
  final String location;
  final String date;
  final String startTime;
  final String endTime;
  final String bookedAt;

  String get sportEmoji => sportType == 'badminton' ? '🏸' : '⚽';
}
