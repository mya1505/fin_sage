import 'package:fin_sage/data/repositories/auth_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._googleSignIn);

  final GoogleSignIn _googleSignIn;

  @override
  Future<bool> isSignedIn() async {
    if (_googleSignIn.currentUser != null) {
      return true;
    }
    final account = await _googleSignIn.signInSilently();
    return account != null;
  }

  @override
  Future<bool> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    return account != null;
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      // Ignore disconnect errors and continue sign-out.
    }
    await _googleSignIn.signOut();
  }
}
