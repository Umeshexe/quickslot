import 'package:flutter/material.dart';

class VenueDetailScreen extends StatelessWidget {
  const VenueDetailScreen({super.key, required this.venueId});
  final int venueId;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Venue Detail — coming soon')),
    );
  }
}
