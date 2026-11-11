enum ViewStatus {
  initial,
  loading,
  empty,
  error,
  success,
}

sealed class UiState<T> {
  const UiState();
}

class UiInitial<T> extends UiState<T> {
  const UiInitial();
}

class UiLoading<T> extends UiState<T> {
  final String? message;
  const UiLoading([this.message]);
}

class UiEmpty<T> extends UiState<T> {
  final String message;
  const UiEmpty(this.message);
}

class UiError<T> extends UiState<T> {
  final String message;
  final dynamic cause;
  const UiError(this.message, [this.cause]);
}

class UiSuccess<T> extends UiState<T> {
  final T data;
  const UiSuccess(this.data);
}
