import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/di/injection.dart';
import 'core/di/session_manager.dart';
import 'core/feature_flags/feature_flags.dart';
import 'core/notifications/notification_service.dart';
import 'core/observability/analytics_service.dart';
import 'core/observability/crash_reporting.dart';
import 'core/storage/secure_storage.dart';
import 'core/storage/server_account_migration.dart';
import 'data/repositories/server_account_repository_impl.dart';
import 'domain/repositories/server_account_repository.dart';
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

  // Restore server URL from saved accounts if it was cleared
  if (!AppConfig.isServerConfigured) {
    final repo = ServerAccountRepositoryImpl();
    final active = await repo.getActive();
    if (active != null) {
      await AppConfig.setServerUrl(active.serverUrl);
    }
  }

  if (AppConfig.isServerConfigured) {
    await initDependencies();

    // Migrate single-server data to multi-server format
    final migration = ServerAccountMigration(
      repository: sl<ServerAccountRepository>(),
      secureStorage: sl<SecureStorage>(),
    );
    await migration.migrateIfNeeded();

    // Create sessions for all accounts; activate the last-used one
    await _initAllSessions();

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

Future<void> _initAllSessions() async {
  final accountRepo = sl<ServerAccountRepository>();
  final sessionManager = sl<SessionManager>();

  // Create a session for every stored account
  final accounts = await accountRepo.getAll();
  for (final account in accounts) {
    sessionManager.createSession(account);
  }

  // Activate the last-used account
  final active = await accountRepo.getActive();
  if (active != null) {
    sessionManager.switchTo(active.id);
  }
}
