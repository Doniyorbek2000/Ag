import 'package:flutter_test/flutter_test.dart';
import 'package:adm_ai/services/crash_reporting_service.dart';

void main() {
  group('CrashReportingService', () {
    test('isConfigured is false without a SENTRY_DSN compile-time define', () {
      // No --dart-define=SENTRY_DSN=... is passed when running tests, so the
      // service must report itself as unconfigured rather than crash on init.
      expect(CrashReportingService.isConfigured, isFalse);
    });

    test('setUserId, breadcrumb and recordError are no-ops when unconfigured', () async {
      expect(() => CrashReportingService.setUserId('anon-123'), returnsNormally);
      expect(() => CrashReportingService.breadcrumb('user tapped send'), returnsNormally);
      await CrashReportingService.recordError(Exception('boom'), StackTrace.current, context: 'test');
    });
  });
}
