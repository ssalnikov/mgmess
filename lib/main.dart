import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/di/injection.dart';
import 'core/feature_flags/feature_flags.dart';
import 'core/notifications/notification_service.dart';
import 'core/observability/analytics_service.dart';
import 'core/observability/crash_reporting.dart';
import 'presentation/widgets/restart_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Limit in-memory image cache: max 100 images or 50 MB
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024;

  // Firebase init is conditional — works only when native configs are present
  // (google-services.json / GoogleService-Info.plist)
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase not configured — push notifications will be disabled
  }

  await AppConfig.loadFromStorage();

  if (AppConfig.isServerConfigured) {
    await initDependencies();

    // Initialize feature flags before other services can query them
    await sl<FeatureFlagService>().init();

    await sl<AnalyticsService>().init();
    await sl<NotificationService>().init();
  }

  // Sentry wraps the app runner to catch unhandled exceptions.
  // If DSN is empty, it runs the app normally without Sentry.
  await CrashReporting.init(
    appRunner: () => runApp(const RestartWidget(child: App())),
  );
}
