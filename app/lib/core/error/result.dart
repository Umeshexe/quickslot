// simple result wrapper so I don't have to try/catch in every screen
// repositories return this and the UI just switches on it
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

class Failure<T> extends Result<T> {
  const Failure(this.message, {this.code});
  final String message;
  // code lets the UI know WHY it failed e.g. 'SLOT_TAKEN' vs a generic error
  final String? code;
}
