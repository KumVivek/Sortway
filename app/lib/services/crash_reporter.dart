import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Crash reporting. No user id and no personal custom keys are ever set
/// (plan §8), for any age band.
abstract class CrashReporter {
  Future<void> recordError(Object error, StackTrace? stack, {bool fatal});
  void recordFlutterError(FlutterErrorDetails details);
}

class CrashlyticsReporter implements CrashReporter {
  CrashlyticsReporter(this._c);

  final FirebaseCrashlytics _c;

  Future<void> initialize() => _c.setCrashlyticsCollectionEnabled(!kDebugMode);

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) => _c.recordError(error, stack, fatal: fatal);

  @override
  void recordFlutterError(FlutterErrorDetails details) =>
      _c.recordFlutterFatalError(details);
}

/// Fake: keeps errors in memory and prints them in debug builds.
class LocalCrashReporter implements CrashReporter {
  final List<Object> errors = [];

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) async {
    errors.add(error);
    debugPrint('[crash] $error\n${stack ?? ''}');
  }

  @override
  void recordFlutterError(FlutterErrorDetails details) {
    errors.add(details.exception);
    FlutterError.presentError(details);
  }
}
