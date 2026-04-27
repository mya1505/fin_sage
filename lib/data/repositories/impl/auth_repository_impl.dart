import 'package:fin_sage/data/repositories/auth_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._googleSignIn);

  final GoogleSignIn _googleSignIn;

  @override
  Future<bool> isSignedIn() async => _googleSignIn.currentUser != null;

  @override
  Future<bool> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    return account != null;
  }

  @override
  Future<void> signOut() => _googleSignIn.signOut();
}
