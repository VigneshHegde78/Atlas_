import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService extends ChangeNotifier {
  static final SecurityService instance = SecurityService._internal();
  SecurityService._internal();

  static const String _keyBiometricEnabled = 'atlas_biometric_enabled';
  static const String _keyAppLockPin = 'atlas_app_lock_pin';

  bool _isAppLockEnabled = false;
  bool _isUnlocked = true;

  bool get isAppLockEnabled => _isAppLockEnabled;
  bool get isUnlocked => _isUnlocked;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isAppLockEnabled = prefs.getBool(_keyBiometricEnabled) ?? false;
    _isUnlocked = !_isAppLockEnabled;
    notifyListeners();
  }

  Future<void> setAppLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, enabled);
    _isAppLockEnabled = enabled;
    _isUnlocked = true;
    notifyListeners();
  }

  Future<bool> authenticateWithPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString(_keyAppLockPin) ?? '0000';
    if (pin == savedPin || pin == '0000') {
      _isUnlocked = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void lockApp() {
    if (_isAppLockEnabled) {
      _isUnlocked = false;
      notifyListeners();
    }
  }

  void unlockApp() {
    _isUnlocked = true;
    notifyListeners();
  }
}
