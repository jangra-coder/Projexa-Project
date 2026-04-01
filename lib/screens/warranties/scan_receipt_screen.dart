import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/ocr_service.dart';
import '../../theme/app_colors.dart';
import 'add_warranty_screen.dart';

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  final OcrService _ocrService = OcrService();
  final ImagePicker _picker = ImagePicker();

  File? _image;
  bool _isProcessing = false;
  Map<String, String?>? _extractedData;
  List<String>? _rawTextBlocks;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _captureImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 90,
    );
    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      _isProcessing = true;
      _extractedData = null;
      _rawTextBlocks = null;
    });

    try {
      final recognizedText = await _ocrService.recognizeText(_image!);
      final data = _ocrService.extractBillData(recognizedText);
      final blocks = _ocrService.getTextBlocks(recognizedText);

      setState(() {
        _extractedData = data;
        _rawTextBlocks = blocks;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OCR failed: $e'),
            backgroundColor: AppColors.dangerRed,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _proceedWithData() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AddWarrantyScreen(
          prefilledData: _extractedData,
          receiptImageFile: _image,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? AppColors.darkText : AppColors.lightText,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.bannerGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.document_scanner_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Smart Scan',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Take a photo of your bill and we\'ll auto-extract the details',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Image capture buttons
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Take Photo',
                    color: AppColors.accentTeal,
                    onTap: () => _captureImage(ImageSource.camera),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.photo_library_rounded,
                    label: 'From Gallery',
                    color: AppColors.accentBlue,
                    onTap: () => _captureImage(ImageSource.gallery),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Image preview
            if (_image != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _image!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Processing indicator
            if (_isProcessing)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? AppColors.accentTeal : AppColors.accentBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Scanning text...',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.darkSubtext
                            : AppColors.lightSubtext,
                      ),
                    ),
                  ],
                ),
              ),

            // Extracted data
            if (_extractedData != null && !_isProcessing) ...[
              Text(
                'EXTRACTED DATA',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 12),

              _ExtractedField(
                icon: Icons.store_outlined,
                label: 'Store Name',
                value: _extractedData!['storeName'],
                isDark: isDark,
              ),
              _ExtractedField(
                icon: Icons.inventory_2_outlined,
                label: 'Product Name',
                value: _extractedData!['productName'],
                isDark: isDark,
              ),
              _ExtractedField(
                icon: Icons.calendar_today_outlined,
                label: 'Date',
                value: _extractedData!['date'],
                isDark: isDark,
              ),
              _ExtractedField(
                icon: Icons.currency_rupee_rounded,
                label: 'Amount',
                value: _extractedData!['amount'] != null
                    ? '₹${_extractedData!['amount']}'
                    : null,
                isDark: isDark,
              ),
              const SizedBox(height: 20),

              // Raw text (collapsed)
              if (_rawTextBlocks != null && _rawTextBlocks!.isNotEmpty)
                ExpansionTile(
                  title: Text(
                    'Raw Scanned Text',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 12),
                  children: _rawTextBlocks!
                      .map(
                        (block) => Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCardBg
                                : AppColors.lightInputBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            block,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkSubtext
                                  : AppColors.lightSubtext,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 16),

              // Proceed button
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
                    onPressed: _proceedWithData,
                    icon: const Icon(Icons.check_rounded, color: Colors.white),
                    label: const Text(
                      'Use This Data',
                      style: TextStyle(
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

            // Empty state
            if (_image == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 64,
                        color: (isDark
                                ? AppColors.darkSubtext
                                : AppColors.lightSubtext)
                            .withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Capture a bill or receipt to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDark ? 0.15 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExtractedField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final bool isDark;

  const _ExtractedField({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.accentBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    value ?? 'Not detected',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: value != null
                          ? (isDark
                              ? AppColors.darkText
                              : AppColors.lightText)
                          : (isDark
                                  ? AppColors.darkSubtext
                                  : AppColors.lightSubtext)
                              .withValues(alpha: 0.5),
                      fontStyle:
                          value == null ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (value != null)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.activeGreen,
                size: 20,
              )
            else
              Icon(
                Icons.help_outline_rounded,
                color: AppColors.warningAmber.withValues(alpha: 0.5),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
