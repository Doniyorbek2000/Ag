# Crash reporting & analytics setup (Sentry)

`CrashReportingService` (`lib/services/crash_reporting_service.dart`) wraps
[Sentry](https://sentry.io) for crash/error reporting, and `AnalyticsService`
(`lib/services/analytics_service.dart`) forwards tracked events to it as
breadcrumbs. Both already work without any setup -- crashes and events are
logged locally and stored in Hive for on-device inspection. Uploading them to
Sentry needs one thing **only the Sentry project owner can create**: a DSN.

## 1. Create a Sentry project (once)

1. Sign up / log in at [sentry.io](https://sentry.io).
2. Create a new project, platform **Flutter**.
3. Open Settings → Projects → (your project) → Client Keys (DSN) and copy the
   DSN, e.g. `https://abcd1234@o123456.ingest.sentry.io/7890123`.

## 2. Build with the DSN

The DSN is read from the compile-time define `SENTRY_DSN` -- never hard-coded,
so it's safe to keep out of source control:

```
flutter run --dart-define=SENTRY_DSN=https://abcd1234@o123456.ingest.sentry.io/7890123

flutter build appbundle --release \
  --dart-define=SENTRY_DSN=https://abcd1234@o123456.ingest.sentry.io/7890123
```

To wire it into the `Android Release Build` GitHub Actions workflow, add a
repository secret `SENTRY_DSN` and pass it the same way:

```yaml
- run: flutter build appbundle --release --dart-define=SENTRY_DSN=${{ secrets.SENTRY_DSN }}
```

## Without a DSN

`CrashReportingService.isConfigured` is `false`, `SentryFlutter.init` is never
called, and the app runs exactly as before -- uncaught errors are still caught
and logged locally via `Logger` (visible in `flutter run` / `adb logcat`),
just not uploaded anywhere.

## What gets reported

- **Crashes**: uncaught Flutter and platform-dispatcher errors, captured
  automatically by `CrashReportingService.init`.
- **Handled errors**: call sites that catch an exception worth tracking use
  `CrashReportingService.recordError(error, stackTrace, context: '...')`
  (e.g. `chat_provider.dart` records AI request failures under the
  `chat_send_message` context).
- **User correlation**: a stable, anonymous per-install UUID (generated once
  and persisted in `SharedPreferences`, never tied to name/email) is attached
  via `CrashReportingService.setUserId` so crash reports can be grouped by
  device without sending any personally identifiable information.
- **Breadcrumbs**: every `AnalyticsService().track(...)` / `screenView(...)`
  call becomes a Sentry breadcrumb, so crash reports show what the user was
  doing right before the crash (which screen, which action, etc).

## Swapping in a hosted analytics platform later

`AnalyticsService` is intentionally provider-agnostic: every event is logged,
stored locally in a capped Hive box (`analytics_events`, inspectable via
`AnalyticsService().recentEvents()`), and forwarded to Sentry as a breadcrumb.
When you decide on a platform (Mixpanel, Amplitude, PostHog, Firebase
Analytics, ...), the only place that needs to change is `_dispatch` in
`lib/services/analytics_service.dart` -- every call site
(`AnalyticsService().track('...')`) stays exactly the same.
