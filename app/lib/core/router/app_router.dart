import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quickslot/features/auth/presentation/screens/user_select_screen.dart';
import 'package:quickslot/features/venues/presentation/screens/venue_list_screen.dart';
import 'package:quickslot/features/venues/presentation/screens/venue_detail_screen.dart';
import 'package:quickslot/features/bookings/presentation/screens/booking_confirm_screen.dart';
import 'package:quickslot/features/bookings/presentation/screens/my_bookings_screen.dart';

class Routes {
  static const userSelect = '/';
  static const venueList = '/venues';
  static const venueDetail = '/venues/:id';
  static const bookingConfirm = '/booking/confirm';
  static const myBookings = '/my-bookings';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.userSelect,
    routes: [
      GoRoute(
        path: Routes.userSelect,
        builder: (context, state) => const UserSelectScreen(),
      ),
      GoRoute(
        path: Routes.venueList,
        builder: (context, state) => const VenueListScreen(),
      ),
      GoRoute(
        path: Routes.venueDetail,
        builder: (context, state) {
          final venueId = int.parse(state.pathParameters['id']!);
          return VenueDetailScreen(venueId: venueId);
        },
      ),
      GoRoute(
        path: Routes.bookingConfirm,
        // passing slot data via extra instead of query params
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return BookingConfirmScreen(
            slotId: extra['slotId'] as int,
            venueName: extra['venueName'] as String,
            date: extra['date'] as String,
            startTime: extra['startTime'] as String,
            endTime: extra['endTime'] as String,
          );
        },
      ),
      GoRoute(
        path: Routes.myBookings,
        builder: (context, state) => const MyBookingsScreen(),
      ),
    ],
  );
});
