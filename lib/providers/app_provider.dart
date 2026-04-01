import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../models/warranty_model.dart';
import '../services/auth_service.dart';
import '../services/drive_service.dart';
import '../services/firestore_warranty_service.dart';

class AppProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreWarrantyService _warrantyService = FirestoreWarrantyService();
  final DriveService _driveService = DriveService();

  // Theme
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  // Auth state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UserModel? get currentUser => _authService.currentUser;
  bool get isLoggedIn => _authService.isLoggedIn;

  // Drive state
  bool get isDriveConnected => _driveService.isInitialized;
  bool get hasGoogleAccount => _authService.hasDriveAccess;

  // Warranty state
  List<WarrantyModel> get warranties => _warrantyService.warranties;
  List<WarrantyModel> get activeWarranties => _warrantyService.activeWarranties;
  List<WarrantyModel> get expiringSoonWarranties =>
      _warrantyService.expiringSoonWarranties;
  List<WarrantyModel> get expiredWarranties =>
      _warrantyService.expiredWarranties;

  // Settings
  bool _pushNotifications = true;
  bool get pushNotifications => _pushNotifications;

  // Search
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  List<WarrantyModel> get filteredWarranties {
    if (_searchQuery.isEmpty) return warranties;
    return _warrantyService.searchWarranties(_searchQuery);
  }

  Future<void> initialize() async {
    await _loadSettings();

    // Set up the Firestore real-time listener callback
    _warrantyService.onDataChanged = () {
      notifyListeners();
    };

    // If user is already logged in (app restart), initialize services
    if (_authService.isLoggedIn) {
      final uid = _authService.currentUser?.id;
      if (uid != null) {
        await _warrantyService.initialize(uid);
      }
      // Try to initialize Drive if Google account is available
      await _tryInitDrive();
    }

    notifyListeners();
  }

  // Theme management
  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _pushNotifications = prefs.getBool('pushNotifications') ?? true;
  }

  // ─── Auth methods ────────────────────────────────────

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.login(email, password);
      // Initialize Firestore for this user
      final uid = _authService.currentUser?.id;
      if (uid != null) {
        await _warrantyService.initialize(uid);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(
      String email, String password, String confirmPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signUp(email, password, confirmPassword);
      // Initialize Firestore for this new user
      final uid = _authService.currentUser?.id;
      if (uid != null) {
        await _warrantyService.initialize(uid);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signInWithGoogle();
      // Initialize both Firestore and Drive
      final uid = _authService.currentUser?.id;
      if (uid != null) {
        await _warrantyService.initialize(uid);
      }
      await _tryInitDrive();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    await _warrantyService.dispose();
    _driveService.dispose();
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Google Drive ────────────────────────────────────

  /// Attempt to initialize Google Drive. Fails silently if no Google account.
  Future<void> _tryInitDrive() async {
    try {
      final accessToken = _authService.driveAccessToken;
      if (accessToken == null) return;
      await _driveService.initialize(accessToken);
    } catch (_) {
      // Not critical — user can still use the app without Drive
    }
    notifyListeners();
  }

  /// For email-only users: connect their Google Drive.
  Future<bool> connectGoogleDrive() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.connectGoogleDrive();
      if (success) {
        await _tryInitDrive();
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Upload a product image to Google Drive.
  Future<String?> uploadProductImage(File file, String warrantyId) async {
    if (!_driveService.isInitialized) return null;
    try {
      final result =
          await _driveService.uploadImage(file, warrantyId, 'product');
      return result['fileId'];
    } catch (_) {
      return null;
    }
  }

  /// Upload a receipt image to Google Drive.
  Future<String?> uploadReceiptImage(File file, String warrantyId) async {
    if (!_driveService.isInitialized) return null;
    try {
      final result =
          await _driveService.uploadImage(file, warrantyId, 'receipt');
      return result['fileId'];
    } catch (_) {
      return null;
    }
  }

  /// Get a downloadable URL for a Drive file.
  String? getDriveImageUrl(String? fileId) {
    if (fileId == null) return null;
    return _driveService.getDownloadUrl(fileId);
  }

  // ─── Warranty methods ────────────────────────────────

  Future<void> addWarranty(WarrantyModel warranty) async {
    await _warrantyService.addWarranty(warranty);
    notifyListeners();
  }

  Future<void> updateWarranty(WarrantyModel warranty) async {
    await _warrantyService.updateWarranty(warranty);
    notifyListeners();
  }

  Future<void> deleteWarranty(String id) async {
    // Also delete Drive images if present
    final warranty = _warrantyService.getWarrantyById(id);
    if (warranty != null) {
      if (warranty.productImageDriveId != null) {
        await _driveService.deleteImage(warranty.productImageDriveId!);
      }
      if (warranty.receiptImageDriveId != null) {
        await _driveService.deleteImage(warranty.receiptImageDriveId!);
      }
    }
    await _warrantyService.deleteWarranty(id);
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<WarrantyModel> filterByCategory(WarrantyCategory category) {
    return _warrantyService.filterByCategory(category);
  }

  // ─── Settings ────────────────────────────────────────

  Future<void> togglePushNotifications() async {
    _pushNotifications = !_pushNotifications;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pushNotifications', _pushNotifications);
    notifyListeners();
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;
}
