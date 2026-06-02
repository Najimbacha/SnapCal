import 'package:flutter/foundation.dart';

import '../state/async_ui_state.dart';
import 'app_failure.dart';
import 'app_result.dart';
import 'operation_gate.dart';

mixin ResilientProviderMixin on ChangeNotifier {
  final OperationGate operationGate = OperationGate();
  int _operationGeneration = 0;
  bool _disposed = false;

  bool get isProviderActive => !_disposed;
  int get operationGeneration => _operationGeneration;

  int nextOperationGeneration() => ++_operationGeneration;

  bool isCurrentOperation(int generation) =>
      !_disposed && generation == _operationGeneration;

  bool canStartOperation(String key) => operationGate.tryAcquire(key);

  void finishOperation(String key) => operationGate.release(key);

  AsyncUiState stateFromResult<T>(
    AppResult<T> result, {
    required bool isEmpty,
    String? emptyMessage,
    int pendingCount = 0,
  }) {
    if (result.isSuccess) {
      return isEmpty
          ? AsyncUiState.empty(emptyMessage)
          : AsyncUiState.success(lastUpdatedAt: DateTime.now());
    }

    final failure = result.failure!;
    if (failure.isOfflineLike && result.hasFallback) {
      return AsyncUiState.partial(
        message: failure.message,
        failure: failure,
        pendingCount: pendingCount,
      );
    }
    if (failure.isOfflineLike) {
      return AsyncUiState.offline(failure.message, failure);
    }
    return AsyncUiState.error(failure.message, failure);
  }

  AsyncUiState stateFromFailure(
    AppFailure failure, {
    bool hasFallback = false,
    int pendingCount = 0,
  }) {
    if (failure.isOfflineLike && hasFallback) {
      return AsyncUiState.partial(
        message: failure.message,
        failure: failure,
        pendingCount: pendingCount,
      );
    }
    if (failure.isOfflineLike) {
      return AsyncUiState.offline(failure.message, failure);
    }
    return AsyncUiState.error(failure.message, failure);
  }

  @override
  void dispose() {
    _disposed = true;
    _operationGeneration++;
    super.dispose();
  }
}
