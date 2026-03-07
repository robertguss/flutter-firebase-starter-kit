import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
    : firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth firebaseAuth;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in was cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return firebaseAuth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithApple() async {
    final appleProvider = AppleAuthProvider();
    return firebaseAuth.signInWithProvider(appleProvider);
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<void> deleteAccount() async {
    final user = firebaseAuth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }
}
