enum WarrantyCategory {
  electronics('Electronics', '📱'),
  appliances('Appliances', '🏠'),
  vehicles('Vehicles', '🚗'),
  furniture('Furniture', '🪑'),
  clothing('Clothing', '👔'),
  healthFitness('Health & Fitness', '💪'),
  tools('Tools', '🔧'),
  software('Software', '💻'),
  jewelry('Jewelry', '💍'),
  other('Other', '📦');

  final String label;
  final String emoji;
  const WarrantyCategory(this.label, this.emoji);
}

enum WarrantyStatus {
  active,
  expiringSoon, // within 30 days
  expired,
}

class WarrantyModel {
  final String id;
  final String productName;
  final String? brand;
  final WarrantyCategory category;
  final DateTime purchaseDate;
  final DateTime warrantyEndDate;
  final String? productImagePath; // Local file path
  final String? receiptImagePath; // Local file path
  final String? productImageDriveId; // Google Drive file ID
  final String? receiptImageDriveId; // Google Drive file ID
  final String? notes;
  final double? purchasePrice;
  final String? serialNumber;
  final String? storeName;
  final DateTime createdAt;

  WarrantyModel({
    required this.id,
    required this.productName,
    this.brand,
    required this.category,
    required this.purchaseDate,
    required this.warrantyEndDate,
    this.productImagePath,
    this.receiptImagePath,
    this.productImageDriveId,
    this.receiptImageDriveId,
    this.notes,
    this.purchasePrice,
    this.serialNumber,
    this.storeName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  WarrantyStatus get status {
    final now = DateTime.now();
    if (warrantyEndDate.isBefore(now)) {
      return WarrantyStatus.expired;
    }
    final daysLeft = warrantyEndDate.difference(now).inDays;
    if (daysLeft <= 30) {
      return WarrantyStatus.expiringSoon;
    }
    return WarrantyStatus.active;
  }

  int get daysRemaining {
    return warrantyEndDate.difference(DateTime.now()).inDays;
  }

  String get daysRemainingText {
    final days = daysRemaining;
    if (days < 0) return '${days.abs()} days ago';
    if (days == 0) return 'Expires today';
    if (days == 1) return '1 day left';
    return '$days days';
  }

  /// Whether this warranty has any images stored in Google Drive.
  bool get hasCloudImages =>
      productImageDriveId != null || receiptImageDriveId != null;

  WarrantyModel copyWith({
    String? productName,
    String? brand,
    WarrantyCategory? category,
    DateTime? purchaseDate,
    DateTime? warrantyEndDate,
    String? productImagePath,
    String? receiptImagePath,
    String? productImageDriveId,
    String? receiptImageDriveId,
    String? notes,
    double? purchasePrice,
    String? serialNumber,
    String? storeName,
  }) {
    return WarrantyModel(
      id: id,
      productName: productName ?? this.productName,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      warrantyEndDate: warrantyEndDate ?? this.warrantyEndDate,
      productImagePath: productImagePath ?? this.productImagePath,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      productImageDriveId: productImageDriveId ?? this.productImageDriveId,
      receiptImageDriveId: receiptImageDriveId ?? this.receiptImageDriveId,
      notes: notes ?? this.notes,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      serialNumber: serialNumber ?? this.serialNumber,
      storeName: storeName ?? this.storeName,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productName': productName,
      'brand': brand,
      'category': category.name,
      'purchaseDate': purchaseDate.toIso8601String(),
      'warrantyEndDate': warrantyEndDate.toIso8601String(),
      'productImagePath': productImagePath,
      'receiptImagePath': receiptImagePath,
      'productImageDriveId': productImageDriveId,
      'receiptImageDriveId': receiptImageDriveId,
      'notes': notes,
      'purchasePrice': purchasePrice,
      'serialNumber': serialNumber,
      'storeName': storeName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WarrantyModel.fromMap(Map<String, dynamic> map) {
    return WarrantyModel(
      id: map['id'] ?? '',
      productName: map['productName'] ?? '',
      brand: map['brand'],
      category: WarrantyCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => WarrantyCategory.other,
      ),
      purchaseDate:
          DateTime.tryParse(map['purchaseDate'] ?? '') ?? DateTime.now(),
      warrantyEndDate:
          DateTime.tryParse(map['warrantyEndDate'] ?? '') ?? DateTime.now(),
      productImagePath: map['productImagePath'],
      receiptImagePath: map['receiptImagePath'],
      productImageDriveId: map['productImageDriveId'],
      receiptImageDriveId: map['receiptImageDriveId'],
      notes: map['notes'],
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble(),
      serialNumber: map['serialNumber'],
      storeName: map['storeName'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
