import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/warranty_model.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';

class AddWarrantyScreen extends StatefulWidget {
  /// Pre-filled data from OCR scan (keys: storeName, productName, date, amount).
  final Map<String, String?>? prefilledData;

  /// Receipt image file from scan flow.
  final File? receiptImageFile;

  const AddWarrantyScreen({
    super.key,
    this.prefilledData,
    this.receiptImageFile,
  });

  @override
  State<AddWarrantyScreen> createState() => _AddWarrantyScreenState();
}

class _AddWarrantyScreenState extends State<AddWarrantyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _serialController = TextEditingController();
  final _storeController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  final _picker = ImagePicker();

  WarrantyCategory _selectedCategory = WarrantyCategory.electronics;
  DateTime _purchaseDate = DateTime.now();
  DateTime _warrantyEndDate = DateTime.now().add(const Duration(days: 365));

  File? _productImage;
  File? _receiptImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill from OCR data if available
    if (widget.prefilledData != null) {
      final data = widget.prefilledData!;
      if (data['productName'] != null) {
        _nameController.text = data['productName']!;
      }
      if (data['storeName'] != null) {
        _storeController.text = data['storeName']!;
      }
      if (data['amount'] != null) {
        _priceController.text = data['amount']!;
      }
      if (data['date'] != null) {
        _tryParseDate(data['date']!);
      }
    }
    // Use the receipt image from scan flow
    if (widget.receiptImageFile != null) {
      _receiptImage = widget.receiptImageFile;
    }
  }

  void _tryParseDate(String dateStr) {
    // Try common formats
    final formats = [
      'dd/MM/yyyy',
      'dd-MM-yyyy',
      'dd.MM.yyyy',
      'MM/dd/yyyy',
      'yyyy-MM-dd',
    ];
    for (final fmt in formats) {
      try {
        final d = DateFormat(fmt).parseStrict(dateStr);
        _purchaseDate = d;
        _warrantyEndDate = d.add(const Duration(days: 365));
        return;
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _serialController.dispose();
    _storeController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isProduct) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isProduct ? 'Product Photo' : 'Receipt Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded),
                  title: const Text('Take Photo'),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: const Text('Choose from Gallery'),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() {
      if (isProduct) {
        _productImage = File(picked.path);
      } else {
        _receiptImage = File(picked.path);
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isPurchase) async {
    final initialDate = isPurchase ? _purchaseDate : _warrantyEndDate;
    final firstDate = isPurchase ? DateTime(2010) : _purchaseDate;
    final lastDate = isPurchase ? DateTime.now() : DateTime(2040);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.accentTeal,
                    surface: AppColors.darkSurface,
                  )
                : const ColorScheme.light(
                    primary: AppColors.accentBlue,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isPurchase) {
          _purchaseDate = picked;
          if (_warrantyEndDate.isBefore(_purchaseDate)) {
            _warrantyEndDate = _purchaseDate.add(const Duration(days: 365));
          }
        } else {
          _warrantyEndDate = picked;
        }
      });
    }
  }

  Future<void> _saveWarranty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final provider = context.read<AppProvider>();
    final warrantyId = 'w_${const Uuid().v4().substring(0, 12)}';

    // Upload images to Google Drive if available
    String? productDriveId;
    String? receiptDriveId;

    if (_productImage != null) {
      productDriveId =
          await provider.uploadProductImage(_productImage!, warrantyId);
    }
    if (_receiptImage != null) {
      receiptDriveId =
          await provider.uploadReceiptImage(_receiptImage!, warrantyId);
    }

    final warranty = WarrantyModel(
      id: warrantyId,
      productName: _nameController.text.trim(),
      brand: _brandController.text.trim().isEmpty
          ? null
          : _brandController.text.trim(),
      category: _selectedCategory,
      purchaseDate: _purchaseDate,
      warrantyEndDate: _warrantyEndDate,
      serialNumber: _serialController.text.trim().isEmpty
          ? null
          : _serialController.text.trim(),
      storeName: _storeController.text.trim().isEmpty
          ? null
          : _storeController.text.trim(),
      purchasePrice: _priceController.text.trim().isEmpty
          ? null
          : double.tryParse(_priceController.text.trim()),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      productImagePath: _productImage?.path,
      receiptImagePath: _receiptImage?.path,
      productImageDriveId: productDriveId,
      receiptImageDriveId: receiptDriveId,
    );

    await provider.addWarranty(warranty);

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            productDriveId != null || receiptDriveId != null
                ? 'Warranty saved & images uploaded to Drive!'
                : 'Warranty added successfully!',
          ),
          backgroundColor: AppColors.activeGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM dd, yyyy');
    final driveConnected = context.watch<AppProvider>().isDriveConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Warranty'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? AppColors.darkText : AppColors.lightText,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image pickers
              _buildLabel('Photos', isDark),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _ImagePickerBox(
                      label: 'Product Photo',
                      icon: Icons.camera_alt_rounded,
                      image: _productImage,
                      onTap: () => _pickImage(true),
                      onRemove: () =>
                          setState(() => _productImage = null),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ImagePickerBox(
                      label: 'Bill / Receipt',
                      icon: Icons.receipt_long_rounded,
                      image: _receiptImage,
                      onTap: () => _pickImage(false),
                      onRemove: () =>
                          setState(() => _receiptImage = null),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              if ((_productImage != null || _receiptImage != null) &&
                  !driveConnected)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 14, color: AppColors.warningAmber),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Connect Google Drive in Settings to backup images',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.warningAmber,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // Product name
              _buildLabel('Product Name *', isDark),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: TextStyle(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
                decoration: const InputDecoration(
                  hintText: 'e.g. iPhone 17 Pro',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Product name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Brand
              _buildLabel('Brand', isDark),
              const SizedBox(height: 8),
              TextFormField(
                controller: _brandController,
                style: TextStyle(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
                decoration: const InputDecoration(
                  hintText: 'e.g. Apple',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // Category
              _buildLabel('Category', isDark),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkInputBorder
                        : AppColors.lightInputBorder,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<WarrantyCategory>(
                    value: _selectedCategory,
                    isExpanded: true,
                    dropdownColor:
                        isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    style: TextStyle(
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                      fontSize: 15,
                    ),
                    items: WarrantyCategory.values
                        .map(
                          (cat) => DropdownMenuItem(
                            value: cat,
                            child: Text('${cat.emoji}  ${cat.label}'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Dates
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Purchase Date', isDark),
                        const SizedBox(height: 8),
                        _DateButton(
                          label: dateFormat.format(_purchaseDate),
                          onTap: () => _selectDate(context, true),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Warranty Until *', isDark),
                        const SizedBox(height: 8),
                        _DateButton(
                          label: dateFormat.format(_warrantyEndDate),
                          onTap: () => _selectDate(context, false),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Serial Number
              _buildLabel('Serial Number', isDark),
              const SizedBox(height: 8),
              TextFormField(
                controller: _serialController,
                style: TextStyle(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
                decoration: const InputDecoration(
                  hintText: 'Optional',
                  prefixIcon: Icon(Icons.qr_code_2_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // Store
              _buildLabel('Store / Retailer', isDark),
              const SizedBox(height: 8),
              TextFormField(
                controller: _storeController,
                style: TextStyle(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
                decoration: const InputDecoration(
                  hintText: 'e.g. Amazon, Apple Store',
                  prefixIcon: Icon(Icons.store_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // Price
              _buildLabel('Purchase Price', isDark),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
                decoration: const InputDecoration(
                  hintText: '₹0.00',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                ),
              ),
              const SizedBox(height: 20),

              // Notes
              _buildLabel('Notes', isDark),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                style: TextStyle(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
                decoration: const InputDecoration(
                  hintText: 'Any additional notes...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.notes_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.buttonGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentBlue.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveWarranty,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.add_circle_outline,
                            color: Colors.white),
                    label: Text(
                      _isSaving ? 'Saving...' : 'Add Warranty',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkText : AppColors.lightText,
      ),
    );
  }
}

// ─── Image Picker Box Widget ───────────────────────────

class _ImagePickerBox extends StatelessWidget {
  final String label;
  final IconData icon;
  final File? image;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final bool isDark;

  const _ImagePickerBox({
    required this.label,
    required this.icon,
    required this.image,
    required this.onTap,
    required this.onRemove,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: image == null ? onTap : null,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : AppColors.lightInputBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.lightInputBorder,
            style: image == null ? BorderStyle.solid : BorderStyle.none,
          ),
        ),
        child: image != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(image!, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 28,
                    color: isDark
                        ? AppColors.darkSubtext
                        : AppColors.lightSubtext,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkSubtext
                          : AppColors.lightSubtext,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to add',
                    style: TextStyle(
                      fontSize: 10,
                      color: (isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext)
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Date Button Widget ────────────────────────────────

class _DateButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _DateButton({
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isDark ? AppColors.darkInputBorder : AppColors.lightInputBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: isDark ? AppColors.accentTeal : AppColors.accentBlue,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
