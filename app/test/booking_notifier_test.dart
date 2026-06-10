import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickslot/features/bookings/presentation/providers/booking_provider.dart';

void main() {
  group('BookingNotifier state machine', () {
    test('starts in idle state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(bookingNotifierProvider);
      expect(state.status, BookingStatus.idle);
      expect(state.errorMessage, isNull);
    });

    test('reset() returns to idle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(bookingNotifierProvider.notifier);
      notifier.reset();
      expect(container.read(bookingNotifierProvider).status, BookingStatus.idle);
    });

    test('BookingState defaults have correct values', () {
      const state = BookingState();
      expect(state.status, BookingStatus.idle);
      expect(state.errorMessage, isNull);
    });

    test('BookingState with slotTaken status is correctly set', () {
      const state = BookingState(status: BookingStatus.slotTaken);
      expect(state.status, BookingStatus.slotTaken);
      expect(state.errorMessage, isNull);
    });

    test('BookingState with failed status carries an error message', () {
      const state = BookingState(
        status: BookingStatus.failed,
        errorMessage: 'Network error',
      );
      expect(state.status, BookingStatus.failed);
      expect(state.errorMessage, 'Network error');
    });

    test('BookingStatus enum has exactly 5 states', () {
      expect(BookingStatus.values.length, 5);
      expect(BookingStatus.values, containsAll([
        BookingStatus.idle,
        BookingStatus.loading,
        BookingStatus.success,
        BookingStatus.slotTaken,
        BookingStatus.failed,
      ]));
    });

    test('multiple resets stay idle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(bookingNotifierProvider.notifier);
      notifier.reset();
      notifier.reset();
      expect(container.read(bookingNotifierProvider).status, BookingStatus.idle);
    });

    test('listening to provider fires immediately with idle', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final statuses = <BookingStatus>[];
      container.listen(
        bookingNotifierProvider.select((s) => s.status),
        (_, next) => statuses.add(next),
        fireImmediately: true,
      );

      expect(statuses, [BookingStatus.idle]);
    });
  });
}
