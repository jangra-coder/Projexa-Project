import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
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

  /// Extract structured bill data from raw text.
  ///
  /// Returns a map with keys: productName, date, amount, storeName.
  /// Values may be null if not detected.
  Map<String, String?> extractBillData(String allText) {
    final lines = allText.split('\n').where((l) => l.trim().isNotEmpty).toList();

    return {
      'storeName': _extractStoreName(lines),
      'productName': _extractProductName(lines),
      'date': _extractDate(allText),
      'amount': _extractAmount(allText),
    };
  }

  /// Process a PDF file to extract text and then structured data.
  Future<Map<String, String?>> analyzePdf(File pdfFile) async {
    try {
      final document = PdfDocument(inputBytes: await pdfFile.readAsBytes());
      String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return extractBillData(text);
    } catch (e) {
      throw Exception('Failed to read PDF: $e');
    }
  }

  /// Gets all raw text blocks for display from ML Kit.
  List<String> getTextBlocks(RecognizedText recognizedText) {
    return recognizedText.blocks.map((b) => b.text).toList();
  }

  /// Gets all lines for display from raw text.
  List<String> getRawLines(String rawText) {
    return rawText.split('\n').where((l) => l.trim().isNotEmpty).toList();
  }

  /// Heuristic: store name is typically the first prominent line.
  String? _extractStoreName(List<String> lines) {
    if (lines.isEmpty) return null;
    // First non-empty line is usually the store/merchant name
    return lines.first.trim();
  }

  /// Heuristic: look for a product-like line (not a date or amount).
  String? _extractProductName(List<String> lines) {
    final lowerBoilerplate = [
      'order date', 'order number', 'invoice number', 'invoice date', 
      'invoice details', 'shipping address', 'billing address', 
      'place of supply', 'place of delivery', 'state/ut code', 
      'unit price', 'net amount', 'tax rate', 'tax type', 
      'tax amount', 'total amount', 'amount in words', 
      'sold by', 'authorized signature', 'total:', 'grand total'
    ];

    for (var i = 1; i < lines.length && i < 60; i++) {
      final line = lines[i].trim();
      if (line.length < 5 || line.length > 100) continue;

      // Skip lines that are just numbers, dates, or amounts
      if (_isDateLike(line) || _isAmountLike(line)) continue;

      final lowerLine = line.toLowerCase();
      
      // Skip generic words often found in headers
      if (lowerLine == 'description' || lowerLine == 'hsn' || lowerLine == 'qty' || lowerLine == 'total') {
        continue;
      }

      bool isBoilerplate = false;
      for (final word in lowerBoilerplate) {
        if (lowerLine.contains(word)) {
          isBoilerplate = true;
          break;
        }
      }
      
      if (isBoilerplate) continue;

      // If it looks like a PAN or GSTIN
      if (RegExp(r'^[A-Z0-9]{10,15}$').hasMatch(line)) continue;

      // Found a likely product name
      return line;
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

  /// Extract amount using currency patterns and finding largest value
  String? _extractAmount(String text) {
    String? bestMatch;
    double bestValue = 0;

    // 1. Try explicit currency patterns
    final explicitPatterns = [
      RegExp(r'[₹$]\s*([\d,]+\.?\d*)'),
      RegExp(r'(?:Rs\.?|INR)\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'(?:total|amount|grand\s*total|net\s*amount)[:\s]*[₹$]?\s*([\d,]+\.?\d*)', caseSensitive: false),
    ];

    for (final pattern in explicitPatterns) {
      for (final match in pattern.allMatches(text)) {
        final rawNum = match.group(1) ?? match.group(0) ?? '';
        final numStr = rawNum.replaceAll(RegExp(r'[^\d.]'), '');
        final value = double.tryParse(numStr) ?? 0;
        if (value > bestValue) {
          bestValue = value;
          bestMatch = numStr;
        }
      }
    }

    // 2. If no explicit currency pattern worked well, fall back to max generic decimal
    if (bestValue == 0) {
      // Matches standard decimal formatting like 1,234.00 or 849.50
      final genericDecimalPattern = RegExp(r'\b\d{1,3}(?:,\d{2,3})*\.\d{2}\b');
      for (final match in genericDecimalPattern.allMatches(text)) {
        final numStr = match.group(0)!.replaceAll(',', '');
        final value = double.tryParse(numStr) ?? 0;
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
