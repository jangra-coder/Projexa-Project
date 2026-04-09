import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/warranty_model.dart';

/// Warranty service backed by Cloud Firestore.
///
/// Each user's warranties are stored at: `users/{userId}/warranties`.
/// Real-time updates are streamed via Firestore snapshots.
class FirestoreWarrantyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _subscription;

  List<WarrantyModel> _warranties = [];
  String? _userId;
  bool _initialized = false;

  List<WarrantyModel> get warranties => List.unmodifiable(_warranties);

  List<WarrantyModel> get activeWarranties =>
      _warranties.where((w) => w.status == WarrantyStatus.active).toList();

  List<WarrantyModel> get expiringSoonWarranties =>
      _warranties.where((w) => w.status == WarrantyStatus.expiringSoon).toList();

  List<WarrantyModel> get expiredWarranties =>
      _warranties.where((w) => w.status == WarrantyStatus.expired).toList();

  /// A callback that notifies when warranty data changes from Firestore.
  VoidCallback? onDataChanged;

  CollectionReference get _collection =>
      _firestore.collection('users').doc(_userId).collection('warranties');

  /// Start listening to the user's warranties.
  Future<void> initialize(String userId) async {
    if (_initialized && _userId == userId) return;

    // Clean up previous subscription
    await _subscription?.cancel();

    _userId = userId;
    _initialized = true;

    // Initial load
    final snapshot = await _collection.get();
    _warranties = snapshot.docs
        .map((doc) =>
            WarrantyModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    // The sample data seeding has been removed per user request.
    _sortWarranties();

    // Real-time listener for changes from other devices
    _subscription = _collection.snapshots().listen((snapshot) {
      _warranties = snapshot.docs
          .map((doc) =>
              WarrantyModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      _sortWarranties();
      onDataChanged?.call();
    });
  }

  Future<void> addWarranty(WarrantyModel warranty) async {
    await _collection.doc(warranty.id).set(warranty.toMap());
  }

  Future<void> updateWarranty(WarrantyModel warranty) async {
    await _collection.doc(warranty.id).update(warranty.toMap());
  }

  Future<void> deleteWarranty(String id) async {
    await _collection.doc(id).delete();
  }

  WarrantyModel? getWarrantyById(String id) {
    try {
      return _warranties.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  List<WarrantyModel> searchWarranties(String query) {
    final lowerQuery = query.toLowerCase();
    return _warranties.where((w) {
      return w.productName.toLowerCase().contains(lowerQuery) ||
          (w.brand?.toLowerCase().contains(lowerQuery) ?? false) ||
          w.category.label.toLowerCase().contains(lowerQuery) ||
          (w.storeName?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  List<WarrantyModel> filterByCategory(WarrantyCategory category) {
    return _warranties.where((w) => w.category == category).toList();
  }

  void _sortWarranties() {
    _warranties
        .sort((a, b) => a.warrantyEndDate.compareTo(b.warrantyEndDate));
  }


  /// Clean up Firestore listener.
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _warranties = [];
    _userId = null;
    _initialized = false;
  }
}
