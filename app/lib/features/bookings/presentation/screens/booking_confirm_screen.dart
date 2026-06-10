import 'package:flutter/material.dart';

class BookingConfirmScreen extends StatelessWidget {
  const BookingConfirmScreen({
    super.key,
    required this.slotId,
    required this.venueName,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  final int slotId;
  final String venueName;
  final String date;
  final String startTime;
  final String endTime;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Booking Confirm — coming soon')),
    );
  }
}
