import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'core/notifications/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init is conditional — works only when native configs are present
  // (google-services.json / GoogleService-Info.plist)
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase not configured — push notifications will be disabled
  }

  await initDependencies();
  await sl<NotificationService>().init();
  runApp(const App());
}
