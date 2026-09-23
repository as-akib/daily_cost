import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'supabase_service.dart';

class AuthUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isAnonymous;
  final bool isGoogle;

  const AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isAnonymous = false,
    this.isGoogle = false,
  });

  String? get firstName {
    if (displayName == null || displayName!.trim().isEmpty) return null;
    return displayName!.trim().split(' ').first;
  }
}

class AuthService {
  final sb.SupabaseClient? supabaseClient;
  final SupabaseService supabaseService;

  final StreamController<AuthUser?> _authStateController =
  StreamController<AuthUser?>.broadcast();

  AuthUser? _currentUser;
  bool _initialized = false;

  static const String webClientId =
      '363538586530-hkehkid31ia9e8dg50fbeo6ho9s6ilf7.apps.googleusercontent.com';

  AuthService({
    this.supabaseClient,
    required this.supabaseService,
  }) {
    _initAuth();
  }

  AuthUser? get currentUser => _currentUser;

  Stream<AuthUser?> authStateChanges() => _authStateController.stream;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    await _initAuth();
  }

  Future<void> _initAuth() async {
    final prefs = await SharedPreferences.getInstance();

    if (supabaseClient != null) {
      final session = supabaseClient!.auth.currentSession;
      final user = session?.user;

      if (user != null) {
        _currentUser = _mapSupabaseUser(user);
        _authStateController.add(_currentUser);
      } else {
        final guestId = prefs.getString('dailycost_guest_uid');
        if (guestId != null && guestId.isNotEmpty) {
          _currentUser = AuthUser(
            uid: guestId,
            displayName: guestId,
            isAnonymous: true,
            isGoogle: false,
          );
          _authStateController.add(_currentUser);
        } else {
          _currentUser = null;
          _authStateController.add(null);
        }
      }

      supabaseClient!.auth.onAuthStateChange.listen((data) {
        final sb.AuthChangeEvent event = data.event;
        final sb.Session? currentSession = data.session;

        if ((event == sb.AuthChangeEvent.signedIn ||
            event == sb.AuthChangeEvent.tokenRefreshed ||
            event == sb.AuthChangeEvent.userUpdated) &&
            currentSession != null) {
          _currentUser = _mapSupabaseUser(currentSession.user);
          _authStateController.add(_currentUser);
        } else if (event == sb.AuthChangeEvent.signedOut) {
          final guestId = prefs.getString('dailycost_guest_uid');
          if (guestId != null && guestId.isNotEmpty) {
            _currentUser = AuthUser(
              uid: guestId,
              displayName: guestId,
              isAnonymous: true,
              isGoogle: false,
            );
            _authStateController.add(_currentUser);
          } else {
            _currentUser = null;
            _authStateController.add(null);
          }
        }
      });
    } else {
      final guestId = prefs.getString('dailycost_guest_uid');
      if (guestId != null && guestId.isNotEmpty) {
        _currentUser = AuthUser(
          uid: guestId,
          displayName: guestId,
          isAnonymous: true,
          isGoogle: false,
        );
      } else {
        _currentUser = null;
      }
      _authStateController.add(_currentUser);
    }

    _initialized = true;
  }

  AuthUser _mapSupabaseUser(sb.User user) {
    final rawMeta = user.userMetadata ?? {};
    final isGoogleProvider = user.appMetadata['provider'] == 'google' ||
        user.identities?.any((i) => i.provider == 'google') == true;

    return AuthUser(
      uid: user.id,
      email: user.email,
      displayName: (rawMeta['full_name'] ?? rawMeta['name']) as String?,
      photoUrl: (rawMeta['avatar_url'] ?? rawMeta['picture']) as String?,
      isAnonymous: user.isAnonymous,
      isGoogle: isGoogleProvider,
    );
  }

  Future<AuthUser> signInAnonymously() async {
    final prefs = await SharedPreferences.getInstance();
    final guestUid = 'guest_${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString('dailycost_guest_uid', guestUid);

    _currentUser = AuthUser(
      uid: guestUid,
      email: null,
      displayName: guestUid,
      isAnonymous: true,
      isGoogle: false,
    );
    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  Future<AuthUser> signInWithGoogle() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Web-er jonno direct Supabase OAuth Flow (Popup/Redirect handle kore)
    if (kIsWeb && supabaseClient != null) {
      await prefs.remove('dailycost_guest_uid');
      await supabaseClient!.auth.signInWithOAuth(
        sb.OAuthProvider.google,
        redirectTo: kDebugMode
            ? 'http://localhost:3000'
            : 'https://daily-cost-updated.vercel.app',
        authScreenLaunchMode: sb.LaunchMode.externalApplication,
      );

      final session = supabaseClient!.auth.currentSession;
      if (session != null) {
        _currentUser = _mapSupabaseUser(session.user);
        _authStateController.add(_currentUser);
        return _currentUser!;
      }
      return _currentUser ??
          const AuthUser(uid: 'pending_auth', isAnonymous: false, isGoogle: true);
    }

    // 2. Mobile (Android/iOS)-er jonno Google Sign In Package
    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: webClientId,
      scopes: ['email', 'profile', 'openid'],
    );

    try {
      await googleSignIn.signOut();
    } catch (_) {}

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in was cancelled.');
    }

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (supabaseClient != null) {
      final res = await supabaseClient!.auth.signInWithIdToken(
        provider: sb.OAuthProvider.google,
        idToken: idToken ?? '',
        accessToken: accessToken,
      );

      final user = res.user;
      if (user == null) {
        throw Exception('Supabase failed to authenticate user.');
      }

      await prefs.remove('dailycost_guest_uid');
      _currentUser = _mapSupabaseUser(user);
      _authStateController.add(_currentUser);
      return _currentUser!;
    } else {
      _currentUser = AuthUser(
        uid: googleUser.id,
        email: googleUser.email,
        displayName: googleUser.displayName,
        photoUrl: googleUser.photoUrl,
        isAnonymous: false,
        isGoogle: true,
      );
      _authStateController.add(_currentUser);
      return _currentUser!;
    }
  }

  Future<AuthUser> linkWithGoogle() async {
    return await signInWithGoogle();
  }

  Future<void> updateDisplayName(String newName) async {
    if (_currentUser != null) {
      _currentUser = AuthUser(
        uid: _currentUser!.uid,
        email: _currentUser!.email,
        displayName: newName,
        photoUrl: _currentUser!.photoUrl,
        isAnonymous: _currentUser!.isAnonymous,
        isGoogle: _currentUser!.isGoogle,
      );
      _authStateController.add(_currentUser);
    }

    if (supabaseClient != null) {
      try {
        await supabaseClient!.auth.updateUser(
          sb.UserAttributes(data: {'full_name': newName}),
        );
      } catch (e) {
        debugPrint('Error updating Supabase displayName: $e');
      }
    }
  }

  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('dailycost_guest_uid');
      if (supabaseClient != null) {
        await supabaseClient!.auth.signOut();
      }
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
    _currentUser = null;
    _authStateController.add(null);
  }

  Future<void> deleteAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final guestId = prefs.getString('dailycost_guest_uid');
    if (guestId != null) {
      await supabaseService.deleteUserData(guestId);
      await prefs.remove('dailycost_guest_uid');
    }
    if (_currentUser != null) {
      await supabaseService.deleteUserData(_currentUser!.uid);
    }
    await signOut();
  }
}