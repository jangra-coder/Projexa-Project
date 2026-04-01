import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// On-device OCR service using Google ML Kit.
///
/// Runs entirely offline — no API key or billing required.
class OcrService {
  final TextRecognizer _recognizer = TextRecognizer();

  /// Recognize all text in an image file.
  Future<RecognizedText> recognizeText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    return await _recognizer.processImage(inputImage);
  }

  /// Extract structured bill data from recognized text.
  ///
  /// Returns a map with keys: productName, date, amount, storeName.
  /// Values may be null if not detected.
  Map<String, String?> extractBillData(RecognizedText recognizedText) {
    final allText = recognizedText.text;
    final lines = allText.split('\n').where((l) => l.trim().isNotEmpty).toList();

    return {
      'storeName': _extractStoreName(lines),
      'productName': _extractProductName(lines),
      'date': _extractDate(allText),
      'amount': _extractAmount(allText),
    };
  }

  /// Gets all raw text blocks for display.
  List<String> getTextBlocks(RecognizedText recognizedText) {
    return recognizedText.blocks.map((b) => b.text).toList();
  }

  /// Heuristic: store name is typically the first prominent line.
  String? _extractStoreName(List<String> lines) {
    if (lines.isEmpty) return null;
    // First non-empty line is usually the store/merchant name
    return lines.first.trim();
  }

  /// Heuristic: look for a product-like line (not a date or amount).
  String? _extractProductName(List<String> lines) {
    // Skip first line (store name), look for descriptive text
    for (var i = 1; i < lines.length && i < 10; i++) {
      final line = lines[i].trim();
      // Skip lines that are just numbers, dates, or amounts
      if (_isDateLike(line) || _isAmountLike(line)) continue;
      if (line.length > 3 && line.length < 60) {
        return line;
      }
    }
    return null;
  }

  /// Extract date using common patterns: DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY
  String? _extractDate(String text) {
    final patterns = [
      // DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY
      RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})'),
      // YYYY-MM-DD (ISO)
      RegExp(r'(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})'),
      // DD Mon YYYY (e.g. 15 Jan 2025)
      RegExp(
        r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\w*\s+(\d{2,4})',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(0);
      }
    }
    return null;
  }

  /// Extract amount using currency patterns: ₹, Rs, Rs., INR, $ followed by number
  String? _extractAmount(String text) {
    final patterns = [
      // ₹1,234.56 or Rs 1234 or Rs. 1,234
      RegExp(r'[₹$]\s*[\d,]+\.?\d*'),
      RegExp(r'(?:Rs\.?|INR)\s*[\d,]+\.?\d*', caseSensitive: false),
      // Total: 1234 or Amount: 1234
      RegExp(
        r'(?:total|amount|grand\s*total|net\s*amount)[:\s]*[₹$]?\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
    ];

    String? bestMatch;
    double bestValue = 0;

    for (final pattern in patterns) {
      for (final match in pattern.allMatches(text)) {
        final raw = match.group(0) ?? '';
        final numStr = raw.replaceAll(RegExp(r'[^0-9.]'), '');
        final value = double.tryParse(numStr) ?? 0;
        // Pick the largest amount found (likely the total)
        if (value > bestValue) {
          bestValue = value;
          bestMatch = numStr;
        }
      }
    }

    return bestMatch;
  }

  bool _isDateLike(String text) {
    return RegExp(r'\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4}').hasMatch(text);
  }

  bool _isAmountLike(String text) {
    return RegExp(r'[₹$]|Rs\.?|INR', caseSensitive: false).hasMatch(text) &&
        RegExp(r'\d').hasMatch(text);
  }

  /// Release resources.
  void dispose() {
    _recognizer.close();
  }
}
