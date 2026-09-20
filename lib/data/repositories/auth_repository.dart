import '../services/auth_service.dart';

class AuthRepository {
  final AuthService authService;

  AuthRepository({required this.authService});

  AuthUser? get currentUser => authService.currentUser;

  Stream<AuthUser?> authStateChanges() => authService.authStateChanges();

  Future<AuthUser> signInAnonymously() => authService.signInAnonymously();

  Future<AuthUser> signInWithGoogle() => authService.signInWithGoogle();

  Future<AuthUser> linkWithGoogle() => authService.linkWithGoogle();

  Future<void> updateDisplayName(String newName) =>
      authService.updateDisplayName(newName);

  Future<void> signOut() => authService.signOut();
}
