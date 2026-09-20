import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser, AuthException;
import '../../core/errors/app_exception.dart';

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
    required this.isAnonymous,
    this.isGoogle = false,
  });

  String? get firstName {
    if (displayName == null || displayName!.trim().isEmpty) return null;
    return displayName!.trim().split(' ').first;
  }

  String? get lastName {
    if (displayName == null || displayName!.trim().isEmpty) return null;
    final parts = displayName!.trim().split(' ');
    if (parts.length > 1) {
      return parts.sublist(1).join(' ');
    }
    return null;
  }

  AuthUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isAnonymous,
    bool? isGoogle,
  }) {
    return AuthUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isGoogle: isGoogle ?? this.isGoogle,
    );
  }
}

typedef DataMergeCallback = Future<void> Function(String oldUid, String newUid);

class AuthService {
  final SupabaseClient? supabaseClient;
  final GoogleSignIn _googleSignIn;

  AuthUser? _currentUser;
  final _userStreamController = StreamController<AuthUser?>.broadcast();

  AuthService({
    this.supabaseClient,
    GoogleSignIn? googleSignIn,
  }) : _googleSignIn = googleSignIn ?? GoogleSignIn() {
    _initFromStorage();
  }

  bool get isSupabaseAvailable => supabaseClient != null;

  AuthUser? get currentUser => _currentUser;

  Stream<AuthUser?> authStateChanges() => _userStreamController.stream;

  Future<void> _initFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('dailycost_auth_uid');
      if (uid != null) {
        final email = prefs.getString('dailycost_auth_email');
        final displayName = prefs.getString('dailycost_auth_name');
        final photoUrl = prefs.getString('dailycost_auth_photo');
        final isAnonymous = prefs.getBool('dailycost_auth_is_anon') ?? false;
        final isGoogle = prefs.getBool('dailycost_auth_is_google') ?? false;

        _currentUser = AuthUser(
          uid: uid,
          email: email,
          displayName: displayName,
          photoUrl: photoUrl,
          isAnonymous: isAnonymous,
          isGoogle: isGoogle,
        );
        _userStreamController.add(_currentUser);
      }
    } catch (e) {
      debugPrint('Error loading auth from storage: $e');
    }
  }

  Future<void> _persistUser(AuthUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dailycost_auth_uid', user.uid);
      if (user.email != null) {
        await prefs.setString('dailycost_auth_email', user.email!);
      } else {
        await prefs.remove('dailycost_auth_email');
      }
      if (user.displayName != null) {
        await prefs.setString('dailycost_auth_name', user.displayName!);
      } else {
        await prefs.remove('dailycost_auth_name');
      }
      if (user.photoUrl != null) {
        await prefs.setString('dailycost_auth_photo', user.photoUrl!);
      } else {
        await prefs.remove('dailycost_auth_photo');
      }
      await prefs.setBool('dailycost_auth_is_anon', user.isAnonymous);
      await prefs.setBool('dailycost_auth_is_google', user.isGoogle);
    } catch (_) {}
  }

  /// Continue as Guest
  Future<AuthUser> signInAnonymously() async {
    final prefs = await SharedPreferences.getInstance();
    var guestUid = prefs.getString('dailycost_guest_uid');
    if (guestUid == null) {
      guestUid = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('dailycost_guest_uid', guestUid);
    }

    final user = AuthUser(
      uid: guestUid,
      displayName: 'Guest User',
      isAnonymous: true,
      isGoogle: false,
    );

    _currentUser = user;
    await _persistUser(user);
    _userStreamController.add(user);
    return user;
  }

  /// Sign in with Google
  Future<AuthUser> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthException('Google sign-in was cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      String uid = 'google_${googleUser.id}';
      String? displayName = googleUser.displayName;

      // Extract givenName and familyName if available, or use displayName
      if (displayName == null || displayName.trim().isEmpty) {
        final emailPart = googleUser.email.split('@').first;
        displayName = emailPart;
      }

      if (isSupabaseAvailable && idToken != null) {
        try {
          final res = await supabaseClient!.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: accessToken,
          );
          if (res.user != null) {
            uid = res.user!.id;
          }
        } catch (e) {
          debugPrint('Supabase signInWithIdToken note: $e');
        }
      }

      final user = AuthUser(
        uid: uid,
        email: googleUser.email,
        displayName: displayName,
        photoUrl: googleUser.photoUrl,
        isAnonymous: false,
        isGoogle: true,
      );

      _currentUser = user;
      await _persistUser(user);
      _userStreamController.add(user);
      return user;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Google sign-in failed: $e');
    }
  }

  /// Upgrade guest account with Google
  Future<AuthUser> linkWithGoogle({DataMergeCallback? onMergeData}) async {
    final oldUid = _currentUser?.uid;
    final newUser = await signInWithGoogle();

    if (oldUid != null && oldUid != newUser.uid && onMergeData != null) {
      await onMergeData(oldUid, newUser.uid);
    }

    return newUser;
  }

  /// Update Display Name (with instant UI updates and Supabase sync)
  Future<void> updateDisplayName(String newName) async {
    if (_currentUser == null) return;
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    final updated = _currentUser!.copyWith(displayName: trimmed);
    _currentUser = updated;
    await _persistUser(updated);
    _userStreamController.add(updated);

    if (isSupabaseAvailable && !updated.isAnonymous) {
      try {
        await supabaseClient!.auth.updateUser(
          UserAttributes(data: {'display_name': trimmed}),
        );
        await supabaseClient!.from('profiles').update({
          'display_name': trimmed,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', updated.uid);
      } catch (e) {
        debugPrint('Error updating Supabase user display name: $e');
      }
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      if (isSupabaseAvailable) {
        await supabaseClient?.auth.signOut();
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('dailycost_auth_uid');
      await prefs.remove('dailycost_auth_email');
      await prefs.remove('dailycost_auth_name');
      await prefs.remove('dailycost_auth_photo');
      await prefs.remove('dailycost_auth_is_anon');
      await prefs.remove('dailycost_auth_is_google');
    } catch (_) {}

    _currentUser = null;
    _userStreamController.add(null);
  }

  void dispose() {
    _userStreamController.close();
  }
}
