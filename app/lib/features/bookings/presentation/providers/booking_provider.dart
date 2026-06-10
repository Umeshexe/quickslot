import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickslot/core/error/result.dart';
import 'package:quickslot/features/bookings/data/repositories/booking_repository.dart';
import 'package:quickslot/features/bookings/domain/entities/booking_entity.dart';

// tracks the booking request state: idle / loading / success / failure
enum BookingStatus { idle, loading, success, slotTaken, failed }

class BookingState {
  const BookingState({this.status = BookingStatus.idle, this.errorMessage});
  final BookingStatus status;
  final String? errorMessage;
}

class BookingNotifier extends Notifier<BookingState> {
  @override
  BookingState build() => const BookingState();

  Future<void> book(String userId, int slotId) async {
    state = const BookingState(status: BookingStatus.loading);
    final repo = ref.read(bookingRepositoryProvider);
    final result = await repo.createBooking(userId, slotId);
    state = switch (result) {
      Success() => const BookingState(status: BookingStatus.success),
      Failure(:final message, :final code) => BookingState(
          status: code == 'SLOT_TAKEN' ? BookingStatus.slotTaken : BookingStatus.failed,
          errorMessage: message,
        ),
    };
  }

  void reset() => state = const BookingState();
}

final bookingNotifierProvider =
    NotifierProvider<BookingNotifier, BookingState>(() => BookingNotifier());

// user bookings list
final userBookingsProvider =
    FutureProvider.family<List<BookingEntity>, String>((ref, userId) async {
  final repo = ref.read(bookingRepositoryProvider);
  final result = await repo.getUserBookings(userId);
  return switch (result) {
    Success(:final data) => data,
    Failure(:final message) => throw Exception(message),
  };
});
