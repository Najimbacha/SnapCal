enum AsyncUiPhase { idle, loading, refreshing, success, empty, error }

class AsyncUiState {
  final AsyncUiPhase phase;
  final String? message;

  const AsyncUiState._(this.phase, [this.message]);

  const AsyncUiState.idle() : this._(AsyncUiPhase.idle);
  const AsyncUiState.loading([String? message])
    : this._(AsyncUiPhase.loading, message);
  const AsyncUiState.refreshing([String? message])
    : this._(AsyncUiPhase.refreshing, message);
  const AsyncUiState.success() : this._(AsyncUiPhase.success);
  const AsyncUiState.empty([String? message])
    : this._(AsyncUiPhase.empty, message);
  const AsyncUiState.error([String? message])
    : this._(AsyncUiPhase.error, message);

  bool get isLoading => phase == AsyncUiPhase.loading;
  bool get isRefreshing => phase == AsyncUiPhase.refreshing;
  bool get isBusy => isLoading || isRefreshing;
  bool get isBlocking => phase == AsyncUiPhase.loading;
  bool get hasError => phase == AsyncUiPhase.error;
}
