# What Now? Mobile App - Setup Guide

## Prerequisites

1. **Flutter SDK** (stable 3.24+): https://docs.flutter.dev/get-started/install
2. **Android Studio** with Android SDK (API 34)
3. **Firebase project** configured for Android (`com.whatnow.app`)
4. **AdMob account** with ad unit IDs

## First-Time Setup

### 1. Firebase
- Create a Firebase project at https://console.firebase.google.com
- Add an Android app with package name `com.whatnow.app`
- Download `google-services.json` to `android/app/`
- Enable Analytics, Crashlytics, and Cloud Messaging in Firebase console
- Uncomment the google-services and crashlytics plugins in `android/app/build.gradle`

### 2. AdMob
- Create an AdMob account at https://admob.google.com
- Create banner and interstitial ad units
- Replace test IDs in `lib/core/utils/ad_manager.dart`
- Replace the APPLICATION_ID in `android/app/src/main/AndroidManifest.xml`

### 3. Signing Key (for release builds)
```bash
keytool -genkey -v -keystore whatnow-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias whatnow
```
Copy `android/key.properties.example` to `android/key.properties` and fill in your details.

### 4. Dependencies
```bash
cd mobile
flutter pub get
```

### 5. Generate Hive Adapters (optional - already committed)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Running

```bash
# Debug
flutter run

# Release APK
flutter build apk --release

# Release App Bundle (for Play Store)
flutter build appbundle --release
```

## Testing

```bash
# All tests
flutter test

# Specific test
flutter test test/unit/points_calculator_test.dart

# With coverage
flutter test --coverage
```

## Project Structure

```
lib/
  main.dart                          # App entry point
  app.dart                           # Providers + MaterialApp
  core/
    constants/                       # Colors, points, ranks, task types
    theme/                           # Glassmorphism dark theme
    router/                          # GoRouter with 32 routes
    utils/                           # Points calc, import parser, analytics, ads
    widgets/                         # GlassCard, GlassButton, GlassBottomNav, etc.
    services/                        # Notifications, home widget, biometric
  data/
    models/                          # Hive models (Task, Profile, etc.)
    repositories/                    # Business logic (TaskRepo, SyncRepo, etc.)
    datasources/local/               # Hive storage
    datasources/remote/              # Supabase client
  features/
    auth/                            # Welcome + Login screens
    onboarding/                      # Tutorial carousel
    home/                            # Home screen
    add_task/                        # 6-step add task wizard
    multi_add/                       # 5-step batch add
    import_tasks/                    # Import from text/CSV
    templates/                       # Task templates
    what_next/                       # State selection + swipe cards
    timer/                           # Timer screen
    celebration/                     # Confetti celebration
    manage_tasks/                    # Task list + edit
    gallery/                         # Completed tasks gallery
    calendar/                        # Calendar view
    notifications/                   # Notifications list
    profile/                         # Profile + settings
    groups/                          # Groups + leaderboard
    settings/                        # Subscription/premium
```
