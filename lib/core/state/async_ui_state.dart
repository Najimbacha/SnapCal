import '../resilience/app_failure.dart';

enum AsyncUiPhase {
  idle,
  loading,
  refreshing,
  retrying,
  success,
  empty,
  error,
  offline,
  partial,
}

class AsyncUiState {
  final AsyncUiPhase phase;
  final String? message;
  final AppFailure? failure;
  final DateTime? lastUpdatedAt;
  final bool canRetry;
  final bool isStale;
  final int pendingCount;

  const AsyncUiState._(
    this.phase, {
    this.message,
    this.failure,
    this.lastUpdatedAt,
    this.canRetry = false,
    this.isStale = false,
    this.pendingCount = 0,
  });

  const AsyncUiState.idle() : this._(AsyncUiPhase.idle);
  const AsyncUiState.loading([String? message])
    : this._(AsyncUiPhase.loading, message: message);
  const AsyncUiState.refreshing([String? message])
    : this._(AsyncUiPhase.refreshing, message: message);
  const AsyncUiState.retrying([String? message])
    : this._(AsyncUiPhase.retrying, message: message, canRetry: false);
  const AsyncUiState.success({DateTime? lastUpdatedAt})
    : this._(AsyncUiPhase.success, lastUpdatedAt: lastUpdatedAt);
  const AsyncUiState.empty([String? message])
    : this._(AsyncUiPhase.empty, message: message, canRetry: true);
  const AsyncUiState.error([String? message, AppFailure? failure])
    : this._(
        AsyncUiPhase.error,
        message: message,
        failure: failure,
        canRetry: true,
      );
  const AsyncUiState.offline([String? message, AppFailure? failure])
    : this._(
        AsyncUiPhase.offline,
        message: message,
        failure: failure,
        canRetry: true,
        isStale: true,
      );
  const AsyncUiState.partial({
    String? message,
    AppFailure? failure,
    int pendingCount = 0,
  }) : this._(
         AsyncUiPhase.partial,
         message: message,
         failure: failure,
         canRetry: true,
         isStale: true,
         pendingCount: pendingCount,
       );

  bool get isLoading => phase == AsyncUiPhase.loading;
  bool get isRefreshing => phase == AsyncUiPhase.refreshing;
  bool get isRetrying => phase == AsyncUiPhase.retrying;
  bool get isBusy => isLoading || isRefreshing || isRetrying;
  bool get isBlocking => phase == AsyncUiPhase.loading;
  bool get hasError => phase == AsyncUiPhase.error;
  bool get isOffline => phase == AsyncUiPhase.offline;
  bool get isPartial => phase == AsyncUiPhase.partial;
}
