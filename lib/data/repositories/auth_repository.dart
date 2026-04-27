abstract class AuthRepository {
  Future<bool> signInWithGoogle();
  Future<void> signOut();
  Future<bool> isSignedIn();
}
