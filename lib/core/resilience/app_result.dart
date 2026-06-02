import 'app_failure.dart';

class AppResult<T> {
  final T? data;
  final AppFailure? failure;
  final T? fallbackData;

  const AppResult._({this.data, this.failure, this.fallbackData});

  const AppResult.success(T data) : this._(data: data);

  const AppResult.failure(AppFailure failure, {T? fallbackData})
    : this._(failure: failure, fallbackData: fallbackData);

  bool get isSuccess => failure == null;
  bool get isFailure => failure != null;
  bool get hasFallback => fallbackData != null;

  T get requireData {
    final value = data;
    if (value == null) {
      throw StateError('AppResult has no success data.');
    }
    return value;
  }

  T? get dataOrFallback => data ?? fallbackData;
}
