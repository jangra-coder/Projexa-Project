import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  UserModel? _currentUser;

  /// Store the authorization object for Drive access.
  GoogleSignInClientAuthorization? _driveAuthorization;

  /// Drive scopes to request during Google Sign-In.
  static final List<String> _driveScopes = [
    drive.DriveApi.driveFileScope,
  ];

  AuthService() {
    // Initialize GoogleSignIn on construction
    _initGoogleSignIn();

    // Listen to Firebase auth state changes
    _firebaseAuth.authStateChanges().listen((User? user) {
      if (user != null) {
        _currentUser = UserModel(
          id: user.uid,
          name: user.displayName ?? _extractNameFromEmail(user.email ?? ''),
          email: user.email ?? '',
        );
      } else {
        _currentUser = null;
      }
    });
  }

  Future<void> _initGoogleSignIn() async {
    try {
      await GoogleSignIn.instance.initialize();
    } catch (_) {
      // Already initialized or platform not supported
    }
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _firebaseAuth.currentUser != null;

  /// Whether the user has granted Drive access.
  bool get hasDriveAccess => _driveAuthorization != null;

  /// Get the access token for Google Drive API.
  String? get driveAccessToken => _driveAuthorization?.accessToken;

  // Login with Email/Password
  Future<UserModel> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required');
    }

    try {
      final UserCredential credential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;
      _currentUser = UserModel(
        id: user.uid,
        name: user.displayName ?? _extractNameFromEmail(user.email ?? ''),
        email: user.email ?? '',
      );

      return _currentUser!;
    } catch (e) {
      throw Exception(_getCustomErrorMessage(e));
    }
  }

  // Sign up with Email/Password
  Future<UserModel> signUp(
      String email, String password, String confirmPassword) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('All fields are required');
    }
    if (password.length < 8) {
      throw Exception('Password must be at least 8 characters');
    }
    if (password != confirmPassword) {
      throw Exception('Passwords do not match');
    }

    try {
      final UserCredential credential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;
      _currentUser = UserModel(
        id: user.uid,
        name: _extractNameFromEmail(email),
        email: email,
      );

      return _currentUser!;
    } catch (e) {
      throw Exception(_getCustomErrorMessage(e));
    }
  }

  // Google Sign-In with Drive authorization
  Future<UserModel> signInWithGoogle() async {
    try {
      // Use the v7 API: authenticate() replaces signIn()
      final GoogleSignInAccount? googleUser =
          await GoogleSignIn.instance.authenticate();
      if (googleUser == null) {
        throw Exception('Google Sign-In was cancelled');
      }

      // Get the idToken for Firebase Auth
      final googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      // Request Drive authorization (optional — non-blocking)
      try {
        _driveAuthorization = await googleUser.authorizationClient
            .authorizeScopes(_driveScopes);
      } catch (_) {
        // Drive authorization is optional
      }

      final user = userCredential.user!;
      _currentUser = UserModel(
        id: user.uid,
        name: user.displayName ?? _extractNameFromEmail(user.email ?? ''),
        email: user.email ?? '',
      );

      return _currentUser!;
    } catch (e) {
      throw Exception(_getCustomErrorMessage(e));
    }
  }

  /// Connect Google Drive for email-only users.
  Future<bool> connectGoogleDrive() async {
    try {
      final GoogleSignInAccount? googleUser =
          await GoogleSignIn.instance.authenticate();
      if (googleUser == null) return false;

      // Request Drive scope
      _driveAuthorization = await googleUser.authorizationClient
          .authorizeScopes(_driveScopes);
      return _driveAuthorization != null;
    } catch (e) {
      throw Exception(_getCustomErrorMessage(e));
    }
  }

  /// Silently restore Google Drive access (e.g. on app restart)
  Future<bool> restoreDriveAccess() async {
    try {
      final future = GoogleSignIn.instance.attemptLightweightAuthentication();
      if (future == null) return false;
      
      final GoogleSignInAccount? googleUser = await future;
      if (googleUser == null) return false;

      _driveAuthorization = await googleUser.authorizationClient
          .authorizeScopes(_driveScopes);
      return _driveAuthorization != null;
    } catch (e) {
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {
      // Not signed in with Google
    }
    _driveAuthorization = null;
    _currentUser = null;
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      throw Exception('Please enter a valid email');
    }
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception(_getCustomErrorMessage(e));
    }
  }

  String _extractNameFromEmail(String email) {
    if (email.isEmpty) return 'User';
    final namePart = email.split('@').first;
    return namePart
        .replaceAll('.', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }

  String _getCustomErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'invalid-email':
          return 'The email address is badly formatted.';
        case 'weak-password':
          return 'The password provided is too weak.';
        case 'invalid-credential':
          return 'Invalid credentials. Please verify your email and password.';
        default:
          return error.message ?? 'An unknown authentication error occurred.';
      }
    }
    return error.toString().replaceFirst('Exception: ', '');
  }
}
