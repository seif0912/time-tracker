import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/app_environment.dart';
import 'firebase_options.dart';
import 'package:google_sign_in/google_sign_in.dart';

const appConfig = AppConfig(
  environment: AppEnvironment.production,
  appName: 'Time Tracker',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await GoogleSignIn.instance.initialize();

  runApp(ProviderScope(child: TimeTrackerApp(config: appConfig)));
}
