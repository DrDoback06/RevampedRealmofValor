import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

final firebaseAuthProvider = Provider<fb.FirebaseAuth>((ref) {
  return fb.FirebaseAuth.instance;
});

final authStateProvider = StreamProvider<fb.User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

final authActionsProvider = Provider<AuthActions>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return AuthActions(auth);
});

class AuthActions {
  AuthActions(this._auth);

  final fb.FirebaseAuth _auth;

  Future<void> signInAnonymously() async {
    await _auth.signInAnonymously();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
