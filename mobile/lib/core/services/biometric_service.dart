import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService._();

  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check whether biometric (or device credential) authentication is
  /// available on this device.
  static Future<bool> isAvailable() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();
    return canCheck && isSupported;
  }

  /// Prompt the user to authenticate via biometrics or device PIN/passcode.
  ///
  /// Returns `true` if authentication succeeded, `false` otherwise.
  static Future<bool> authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Unlock What Now?',
        options: const AuthenticationOptions(
          biometricOnly: false, // Allow PIN/passcode fallback
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
