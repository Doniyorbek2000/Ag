import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Crash reporting wrapper around Sentry.
///
/// The DSN is read from a compile-time define (`SENTRY_DSN`) rather than
/// hard-coded -- it's a per-project secret only the Sentry project owner can
/// create (sentry.io → Settings → Projects → Client Keys / DSN). Build with:
///
///   flutter build appbundle --dart-define=SENTRY_DSN=https://xxx@sentry.io/yyy
///
/// Without it, [isConfigured] is false and the app runs normally -- crashes
/// are still logged locally via [Logger] so they show up in `flutter run` /
/// `adb logcat`, just not uploaded anywhere.
class CrashReportingService {
  static const _dsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
  static final Logger _logger = Logger();

  static bool get isConfigured => _dsn.isNotEmpty;

  /// Wraps [runner] (which performs all app bootstrapping and calls
  /// `runApp`) with Sentry's zone-based error capture when configured, or
  /// runs it directly with a local fallback handler otherwise.
  static Future<void> init(FutureOr<void> Function() runner) async {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _report(details.exception, details.stack, hint: 'FlutterError');
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      _report(error, stack, hint: 'PlatformDispatcher');
      return true;
    };

    if (!isConfigured) {
      await runner();
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = _dsn;
        options.tracesSampleRate = 0.2;
        options.environment = kReleaseMode ? 'production' : 'development';
        options.attachStacktrace = true;
      },
      appRunner: runner,
    );
  }

  static void _report(Object error, StackTrace? stack, {String? hint}) {
    _logger.e('Uncaught error${hint != null ? ' ($hint)' : ''}', error: error, stackTrace: stack);
    if (isConfigured) {
      Sentry.captureException(error, stackTrace: stack);
    }
  }

  /// Associates crash reports with the signed-in user (id only -- no PII
  /// such as name/email is sent unless explicitly opted in elsewhere).
  static void setUserId(String? id) {
    if (!isConfigured) return;
    Sentry.configureScope((scope) {
      scope.setUser(id == null ? null : SentryUser(id: id));
    });
  }

  /// Records a handled exception (e.g. a caught API error worth tracking).
  static Future<void> recordError(Object error, StackTrace? stackTrace, {String? context}) async {
    _logger.w('Handled error${context != null ? ' [$context]' : ''}', error: error, stackTrace: stackTrace);
    if (!isConfigured) return;
    await Sentry.captureException(error, stackTrace: stackTrace,
        withScope: context == null
            ? null
            : (scope) => scope.setTag('context', context));
  }

  /// Lightweight breadcrumb -- shows up in the timeline leading up to a
  /// crash, useful for understanding what the user was doing.
  static void breadcrumb(String message, {String? category}) {
    if (!isConfigured) return;
    Sentry.addBreadcrumb(Breadcrumb(message: message, category: category ?? 'app'));
  }
}
