import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/warranty_model.dart';

class WarrantyService {
  static const String _storageKey = 'warranties';

  List<WarrantyModel> _warranties = [];
  bool _initialized = false;

  List<WarrantyModel> get warranties => List.unmodifiable(_warranties);

  List<WarrantyModel> get activeWarranties =>
      _warranties.where((w) => w.status == WarrantyStatus.active).toList();

  List<WarrantyModel> get expiringSoonWarranties =>
      _warranties.where((w) => w.status == WarrantyStatus.expiringSoon).toList();

  List<WarrantyModel> get expiredWarranties =>
      _warranties.where((w) => w.status == WarrantyStatus.expired).toList();

  Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);

    if (stored != null) {
      final List<dynamic> decoded = jsonDecode(stored);
      _warranties =
          decoded.map((e) => WarrantyModel.fromMap(e as Map<String, dynamic>)).toList();
    } else {
      // Load sample data for demo
      _warranties = _getSampleWarranties();
      await _save();
    }

    _warranties.sort((a, b) => a.warrantyEndDate.compareTo(b.warrantyEndDate));
    _initialized = true;
  }

  Future<void> addWarranty(WarrantyModel warranty) async {
    _warranties.add(warranty);
    _warranties.sort((a, b) => a.warrantyEndDate.compareTo(b.warrantyEndDate));
    await _save();
  }

  Future<void> updateWarranty(WarrantyModel warranty) async {
    final index = _warranties.indexWhere((w) => w.id == warranty.id);
    if (index != -1) {
      _warranties[index] = warranty;
      _warranties.sort((a, b) => a.warrantyEndDate.compareTo(b.warrantyEndDate));
      await _save();
    }
  }

  Future<void> deleteWarranty(String id) async {
    _warranties.removeWhere((w) => w.id == id);
    await _save();
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

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(_warranties.map((w) => w.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  List<WarrantyModel> _getSampleWarranties() {
    final now = DateTime.now();
    return [
      WarrantyModel(
        id: 'w001',
        productName: 'iPhone 17 Pro',
        brand: 'Apple',
        category: WarrantyCategory.electronics,
        purchaseDate: now.subtract(const Duration(days: 354)),
        warrantyEndDate: now.add(const Duration(days: 11)),
        purchasePrice: 134900,
        serialNumber: 'DMPXYZ123456',
        storeName: 'Apple Store',
        notes: 'AppleCare+ included',
      ),
      WarrantyModel(
        id: 'w002',
        productName: 'Play Station 5',
        brand: 'Sony',
        category: WarrantyCategory.electronics,
        purchaseDate: now.subtract(const Duration(days: 244)),
        warrantyEndDate: now.add(const Duration(days: 121)),
        purchasePrice: 49990,
        serialNumber: 'PS5-2024-XYZ',
        storeName: 'Amazon',
        notes: 'Digital Edition',
      ),
      WarrantyModel(
        id: 'w003',
        productName: 'Samsung Washing Machine',
        brand: 'Samsung',
        category: WarrantyCategory.appliances,
        purchaseDate: now.subtract(const Duration(days: 180)),
        warrantyEndDate: now.add(const Duration(days: 550)),
        purchasePrice: 32999,
        storeName: 'Flipkart',
      ),
      WarrantyModel(
        id: 'w004',
        productName: 'MacBook Pro 16"',
        brand: 'Apple',
        category: WarrantyCategory.electronics,
        purchaseDate: now.subtract(const Duration(days: 60)),
        warrantyEndDate: now.add(const Duration(days: 305)),
        purchasePrice: 249900,
        serialNumber: 'C02XYZ12345',
        storeName: 'Apple Store',
        notes: 'M4 Max, 48GB RAM',
      ),
      WarrantyModel(
        id: 'w005',
        productName: 'Dyson V15 Detect',
        brand: 'Dyson',
        category: WarrantyCategory.appliances,
        purchaseDate: now.subtract(const Duration(days: 400)),
        warrantyEndDate: now.subtract(const Duration(days: 35)),
        purchasePrice: 56900,
        storeName: 'Dyson India',
      ),
      WarrantyModel(
        id: 'w006',
        productName: 'Office Chair Ergonomic',
        brand: 'Green Soul',
        category: WarrantyCategory.furniture,
        purchaseDate: now.subtract(const Duration(days: 200)),
        warrantyEndDate: now.add(const Duration(days: 895)),
        purchasePrice: 18999,
        storeName: 'Amazon',
      ),
    ];
  }
}
