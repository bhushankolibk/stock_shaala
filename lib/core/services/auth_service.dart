import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google Sign-In only. There is no separate account creation;
/// the Google account IS the account.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _google = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authState => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    final googleUser = await _google.signIn();
    if (googleUser == null) return null; // user cancelled

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCred = await _auth.signInWithCredential(credential);
    return userCred.user;
  }

  Future<void> signOut() async {
    await _google.signOut();
    await _auth.signOut();
  }

  /// "Delete account" — since we only use Google sign-in, this revokes the
  /// Firebase auth record and signs out. Local sim data is wiped separately.
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException {
      // If recent-login is required, fall back to sign out so the user
      // isn't stuck. UI explains they may need to re-auth.
      rethrow;
    } finally {
      await _google.signOut();
    }
  }
}
