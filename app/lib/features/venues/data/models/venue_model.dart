import 'package:quickslot/features/venues/domain/entities/venue_entity.dart';

class VenueModel extends VenueEntity {
  const VenueModel({
    required super.id,
    required super.name,
    required super.sportType,
    required super.location,
    required super.priceInr,
  });

  factory VenueModel.fromJson(Map<String, dynamic> json) {
    return VenueModel(
      id: json['id'] as int,
      name: json['name'] as String,
      sportType: json['sport_type'] as String,
      location: json['location'] as String,
      priceInr: json['price_inr'] as int,
    );
  }
}
