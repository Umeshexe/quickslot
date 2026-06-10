class VenueEntity {
  const VenueEntity({
    required this.id,
    required this.name,
    required this.sportType,
    required this.location,
    required this.priceInr,
  });

  final int id;
  final String name;
  final String sportType;
  final String location;
  final int priceInr;

  String get sportEmoji => sportType == 'badminton' ? '🏸' : '⚽';
}
