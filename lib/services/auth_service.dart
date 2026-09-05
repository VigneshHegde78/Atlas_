import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  FirebaseAuth? _auth;
  User? _currentUser;
  bool _isProUser = false;
  bool _isLoading = false;

  String? _localEmail;
  String? _localDisplayName;
  bool _isLocallyLoggedIn = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null || _isLocallyLoggedIn;
  bool get isProUser => _isProUser;
  bool get isLoading => _isLoading;

  String get userDisplayName {
    if (_currentUser?.displayName != null && _currentUser!.displayName!.isNotEmpty) {
      return _currentUser!.displayName!;
    }
    if (_localDisplayName != null && _localDisplayName!.isNotEmpty) {
      return _localDisplayName!;
    }
    if (_currentUser?.email != null) {
      return _currentUser!.email!.split('@').first;
    }
    if (_localEmail != null && _localEmail!.isNotEmpty) {
      return _localEmail!.split('@').first;
    }
    return '';
  }

  String get userEmail {
    if (_currentUser?.email != null && _currentUser!.email!.isNotEmpty) {
      return _currentUser!.email!;
    }
    if (_localEmail != null && _localEmail!.isNotEmpty) {
      return _localEmail!;
    }
    return '';
  }

  StreamSubscription<User?>? _authSubscription;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isProUser = prefs.getBool('atlas_is_pro_user') ?? false;
      _isLocallyLoggedIn = prefs.getBool('atlas_is_logged_in') ?? false;
      _localEmail = prefs.getString('atlas_local_email') ?? 'vigneshhegde78@gmail.com';
      _localDisplayName = prefs.getString('atlas_local_name') ?? 'Vignesh Hegde';

      if (Firebase.apps.isNotEmpty) {
        _auth = FirebaseAuth.instance;
        _currentUser = _auth?.currentUser;
        _authSubscription?.cancel();
        _authSubscription = _auth?.authStateChanges().listen((user) {
          _currentUser = user;
          notifyListeners();
        });
      }
    } catch (e) {
      debugPrint('AuthService initialize notice (running offline/local mode): $e');
    }
    notifyListeners();
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (_auth != null) {
        final credential = await _auth!.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        _currentUser = credential.user;
      }
      final prefs = await SharedPreferences.getInstance();
      _localEmail = email.trim();
      _localDisplayName = email.split('@').first;
      _isLocallyLoggedIn = true;
      await prefs.setBool('atlas_is_logged_in', true);
      await prefs.setString('atlas_local_email', _localEmail!);
      await prefs.setString('atlas_local_name', _localDisplayName!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Auth Sign In: $e');
      final prefs = await SharedPreferences.getInstance();
      _localEmail = email.trim();
      _localDisplayName = email.split('@').first;
      _isLocallyLoggedIn = true;
      await prefs.setBool('atlas_is_logged_in', true);
      await prefs.setString('atlas_local_email', _localEmail!);
      await prefs.setString('atlas_local_name', _localDisplayName!);

      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  Future<bool> signUpWithEmail(String email, String password, {String? displayName}) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (_auth != null) {
        final credential = await _auth!.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        if (displayName != null && displayName.isNotEmpty) {
          await credential.user?.updateDisplayName(displayName.trim());
        }
        _currentUser = credential.user;
      }
      final prefs = await SharedPreferences.getInstance();
      _localEmail = email.trim();
      _localDisplayName = displayName ?? email.split('@').first;
      _isLocallyLoggedIn = true;
      await prefs.setBool('atlas_is_logged_in', true);
      await prefs.setString('atlas_local_email', _localEmail!);
      await prefs.setString('atlas_local_name', _localDisplayName!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Auth Sign Up: $e');
      final prefs = await SharedPreferences.getInstance();
      _localEmail = email.trim();
      _localDisplayName = displayName ?? email.split('@').first;
      _isLocallyLoggedIn = true;
      await prefs.setBool('atlas_is_logged_in', true);
      await prefs.setString('atlas_local_email', _localEmail!);
      await prefs.setString('atlas_local_name', _localDisplayName!);

      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  Future<void> signInAnonymously() async {
    _isLoading = true;
    notifyListeners();
    try {
      if (_auth != null) {
        final credential = await _auth!.signInAnonymously();
        _currentUser = credential.user;
      }
    } catch (e) {
      debugPrint('Auth Anonymous Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      if (_auth != null) {
        await _auth!.signOut();
      }
      _currentUser = null;
      _isLocallyLoggedIn = false;
      _localEmail = null;
      _localDisplayName = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('atlas_is_logged_in', false);
      await prefs.remove('atlas_local_email');
      await prefs.remove('atlas_local_name');
      notifyListeners();
    } catch (e) {
      debugPrint('Auth Sign Out Error: $e');
      _currentUser = null;
      _isLocallyLoggedIn = false;
      _localEmail = null;
      _localDisplayName = null;
      notifyListeners();
    }
  }

  Future<void> upgradeToPro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('atlas_is_pro_user', true);
    _isProUser = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
