class ApiConstants {
  ApiConstants._();

  // change this to the deployed URL before the demo
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:3000', // 10.0.2.2 is localhost on android emulator
  );

  static const String venues = '/api/venues';
  static String venueSlots(int venueId) => '/api/venues/$venueId/slots';
  static const String bookings = '/api/bookings';
  static String bookingById(int id) => '/api/bookings/$id';
  static String userBookings(String userId) => '/api/users/$userId/bookings';

  // keeping auth simple as per assignment spec
  static const List<String> users = ['user-001', 'user-002', 'user-003'];
}
