import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// Service untuk mengelola autentikasi pengguna via Firebase Auth.
/// Mendukung: Email/Password dan Google Sign-In.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ─── Getters ──────────────────────────────────────────────────────────────

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get isSignedIn => _auth.currentUser != null;

  // ─── Email / Password ─────────────────────────────────────────────────────

  /// Daftar akun baru dengan email dan password.
  /// Otomatis mengupdate displayName setelah registrasi.
  Future<AuthResult> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Simpan nama ke Firebase profile
      await credential.user?.updateDisplayName(name);
      await credential.user?.reload();
      return AuthResult.success(credential.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_translateFirebaseError(e));
    } catch (e) {
      debugPrint('signUpWithEmail error: $e');
      return AuthResult.failure('Terjadi kesalahan: ${e.toString()}');
    }
  }

  /// Login dengan email dan password.
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return AuthResult.success(credential.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_translateFirebaseError(e));
    } catch (e) {
      debugPrint('signInWithEmail error: $e');
      return AuthResult.failure('Terjadi kesalahan: ${e.toString()}');
    }
  }

  /// Kirim email reset password.
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult.success(null);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_translateFirebaseError(e));
    } catch (e) {
      return AuthResult.failure('Gagal mengirim email reset password.');
    }
  }

  // ─── Google Sign-In ───────────────────────────────────────────────────────

  /// Login dengan akun Google.
  /// Memerlukan SHA-1 fingerprint yang sudah didaftarkan di Firebase Console.
  Future<AuthResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User membatalkan sign-in
        return AuthResult.failure('Login Google dibatalkan.');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return AuthResult.success(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_translateFirebaseError(e));
    } catch (e) {
      debugPrint('signInWithGoogle error: $e');
      return AuthResult.failure(
        'Gagal login Google: ${e.toString()}',
      );
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  // ─── Update Profil ────────────────────────────────────────────────────────

  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
    await _auth.currentUser?.reload();
  }

  Future<void> updateEmail(String email) async {
    // updateEmail deprecated in newer Firebase, use verifyBeforeUpdateEmail
    try {
      await _auth.currentUser?.verifyBeforeUpdateEmail(email);
    } catch (e) {
      debugPrint('updateEmail: $e');
    }
  }

  Future<void> updatePhotoUrl(String photoUrl) async {
    await _auth.currentUser?.updatePhotoURL(photoUrl);
    await _auth.currentUser?.reload();
  }

  // ─── Private: Error Translation ───────────────────────────────────────────

  String _translateFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Akun dengan email ini tidak ditemukan.';
      case 'wrong-password':
        return 'Password salah. Coba lagi.';
      case 'invalid-credential':
        return 'Email atau password salah.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Coba login.';
      case 'weak-password':
        return 'Password terlalu lemah (minimal 6 karakter).';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet.';
      case 'operation-not-allowed':
        return 'Metode login ini belum diaktifkan di Firebase.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';
      default:
        return 'Terjadi kesalahan (${e.code}): ${e.message}';
    }
  }
}

/// Hasil dari operasi autentikasi.
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? errorMessage;

  const AuthResult._({
    required this.isSuccess,
    this.user,
    this.errorMessage,
  });

  factory AuthResult.success(User? user) =>
      AuthResult._(isSuccess: true, user: user);

  factory AuthResult.failure(String message) =>
      AuthResult._(isSuccess: false, errorMessage: message);
}
