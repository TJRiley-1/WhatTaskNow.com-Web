import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: Firebase requires google-services.json (Android) and
//       GoogleService-Info.plist (iOS) to be configured before these
//       imports will resolve at runtime.
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'app.dart';
import 'core/services/biometric_service.dart';
import 'core/services/notification_service.dart';
import 'data/datasources/local/hive_datasource.dart';
import 'data/datasources/remote/supabase_datasource.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive (local storage)
  await HiveDatasource.init();

  // Initialize Supabase (remote)
  await SupabaseDatasource.init();

  // TODO: Ensure google-services.json / GoogleService-Info.plist are present
  //       before enabling Firebase initialization.
  await Firebase.initializeApp();

  // Crashlytics: capture Flutter framework errors
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Crashlytics: capture asynchronous errors not caught by Flutter
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Initialize push & local notifications
  await NotificationService.init();
  await NotificationService.requestPermission();

  // Biometric lock check
  final hive = HiveDatasource();
  if (hive.biometricEnabled) {
    final authenticated = await BiometricService.authenticate();
    if (!authenticated) {
      SystemNavigator.pop();
      return;
    }
  }

  runApp(const ProviderScope(child: WhatNowApp()));
}
