// authentication_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check authentication status
  Future<bool> checkAuthenticationStatus() async {
    User? user = _auth.currentUser;
    return user != null;
  }

  // Sign in with email and password
  Future<String?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // Successful login, return null
    } on FirebaseAuthException catch (e) {
      return e.message; // Return error message if login fails
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
