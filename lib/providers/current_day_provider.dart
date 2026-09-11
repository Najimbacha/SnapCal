import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/app_lifecycle_service.dart';
import '../core/utils/date_utils.dart' as app_date;

/// Today's date string, kept current.
///
/// "Today" was read once, when each screen's data first loaded, and never
/// again: left open overnight -- which is how most people leave an app --
/// Home went on showing yesterday's meals, calories and water, and the diary
/// stayed on yesterday, filing the morning's entries there. This moves on at
/// midnight, and on returning to the app, since a timer does not run while
/// the phone has the app suspended.
///
/// Written by hand rather than generated, like [cloudSyncProvider]: one small
/// notifier is not worth a codegen run.
final currentDayProvider = NotifierProvider<CurrentDayNotifier, String>(
  CurrentDayNotifier.new,
);

class CurrentDayNotifier extends Notifier<String> {
  /// The clock, replaceable in tests.
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  Timer? _midnight;

  @override
  String build() {
    final lifecycle = AppLifecycleService();
    void onLifecycle() {
      if (lifecycle.isResumed) refresh();
    }

    lifecycle.addListener(onLifecycle);
    ref.onDispose(() {
      _midnight?.cancel();
      lifecycle.removeListener(onLifecycle);
    });
    _scheduleMidnight();
    return app_date.DateUtils.getDateString(clock());
  }

  /// Moves to the new day, if the date has changed.
  void refresh() {
    final today = app_date.DateUtils.getDateString(clock());
    if (today != state) state = today;
    _scheduleMidnight();
  }

  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = clock();
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(
      next.difference(now) + const Duration(seconds: 1),
      refresh,
    );
  }
}
