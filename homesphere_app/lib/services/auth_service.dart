import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn;

  static const String _gmailScope =
      'https://www.googleapis.com/auth/gmail.readonly';

  /// The currently signed-in user, or null.
  User? get currentUser => _auth.currentUser;

  String? get currentUserEmail => currentUser?.email;

  bool get currentUserHasPasswordProvider =>
      currentUser?.providerData.any(
        (provider) => provider.providerId == EmailAuthProvider.PROVIDER_ID,
      ) ??
      false;

  /// Stream that emits whenever the auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get supportsGoogleSignIn {
    if (kIsWeb) return true;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return false;
    }
  }

  /// Sign in with email and password.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Create a new account with email and password.
  Future<UserCredential> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      await credential.user?.updateDisplayName(name);
      await credential.user?.reload();
    }

    return credential;
  }

  /// Sign in with Google.
  /// Returns the [UserCredential] on success, or null if cancelled.
  Future<UserCredential?> signInWithGoogle() async {
    _ensureGoogleSignInSupported(
      'Google sign-in is only available on Android, iOS, macOS, and web builds.',
    );

    try {
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on PlatformException catch (e) {
      throw AuthFailure(_mapGooglePlatformError(e));
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseAuthError(e));
    }
  }

  Future<void> setOrUpdatePassword({
    required String newPassword,
    String? currentPassword,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw const AuthFailure('No signed-in user found.');
    }

    final email = user.email?.trim();
    if (email == null || email.isEmpty) {
      throw const AuthFailure(
        'This account does not have an email address for password sign-in.',
      );
    }

    final hasPasswordProvider = currentUserHasPasswordProvider;

    try {
      if (hasPasswordProvider) {
        if (currentPassword == null || currentPassword.isEmpty) {
          throw const AuthFailure('Enter your current password.');
        }

        final credential = EmailAuthProvider.credential(
          email: email,
          password: currentPassword,
        );

        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPassword);
      } else {
        final credential = EmailAuthProvider.credential(
          email: email,
          password: newPassword,
        );

        await user.linkWithCredential(credential);
      }

      await user.reload();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(
        _mapPasswordError(e, hasPasswordProvider: hasPasswordProvider),
      );
    }
  }

  /// Get a Google access token WITH Gmail read scope.
  /// Requests the scope on-demand so regular sign-in is unaffected.
  /// Returns null if user cancels or is not signed in with Google.
  Future<String?> getGmailAccessToken() async {
    _ensureGoogleSignInSupported(
      'Gmail import is only available on Android, iOS, macOS, and web builds.',
    );

    try {
      GoogleSignInAccount? googleUser = _googleSignIn.currentUser;
      googleUser ??= await _googleSignIn.signInSilently();

      if (googleUser == null) {
        googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;
      }

      final hasGmailAccess = await _googleSignIn.requestScopes([_gmailScope]);
      if (!hasGmailAccess) {
        return null;
      }

      final auth = await googleUser.authentication;
      return auth.accessToken;
    } on PlatformException catch (e) {
      throw AuthFailure(_mapGooglePlatformError(e));
    }
  }

  /// Sign out the current user (also signs out of Google).
  Future<void> signOut() async {
    if (supportsGoogleSignIn) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }

  /// Send a password reset email to the given email address.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  void _ensureGoogleSignInSupported(String message) {
    if (!supportsGoogleSignIn) {
      throw AuthFailure(message);
    }
  }

  String _mapGooglePlatformError(PlatformException error) {
    switch (error.code) {
      case GoogleSignIn.kSignInCanceledError:
        return 'Google sign-in was canceled.';
      case GoogleSignIn.kNetworkError:
        return 'Google sign-in failed because the device is offline or Google services are unreachable.';
      case GoogleSignIn.kSignInFailedError:
        return 'Google sign-in failed. On Android, this usually means the Firebase OAuth client or SHA fingerprint is misconfigured.';
      case GoogleSignInAccount.kUserRecoverableAuthError:
      case GoogleSignInAccount.kFailedToRecoverAuthError:
        return 'Google account access needs to be re-approved on the device. Try again and complete the consent flow.';
      default:
        final details = error.message?.trim();
        if (details != null && details.isNotEmpty) {
          return details;
        }
        return 'Google sign-in failed with error code "${error.code}".';
    }
  }

  String _mapFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      case 'invalid-credential':
        return 'Google returned an invalid credential. Check the Firebase Google provider and OAuth client configuration.';
      case 'operation-not-allowed':
        return 'Google sign-in is not enabled in Firebase Authentication.';
      case 'user-disabled':
        return 'This Firebase user has been disabled.';
      default:
        return error.message ?? 'Firebase sign-in failed.';
    }
  }

  String _mapPasswordError(
    FirebaseAuthException error, {
    required bool hasPasswordProvider,
  }) {
    switch (error.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Current password is incorrect.';
      case 'weak-password':
        return 'Choose a stronger password with at least 6 characters.';
      case 'requires-recent-login':
        return 'Please sign in again before updating your password.';
      case 'provider-already-linked':
        return 'Password sign-in is already enabled for this account.';
      case 'email-already-in-use':
      case 'credential-already-in-use':
        return 'This email is already linked to another account.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase Authentication.';
      case 'user-mismatch':
        return 'Re-authentication failed for the current user.';
      default:
        if (!hasPasswordProvider &&
            error.message != null &&
            error.message!.trim().isNotEmpty) {
          return error.message!.trim();
        }

        return error.message ?? 'Unable to update password.';
    }
  }
}
