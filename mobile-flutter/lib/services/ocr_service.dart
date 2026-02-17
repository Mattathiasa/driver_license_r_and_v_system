import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  static final _textRecognizer = TextRecognizer();

  /// Extract text from image using Google ML Kit with left/right column detection
  static Future<Map<String, String>> extractDataFromImage(
    String imagePath,
  ) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Parse using improved column-based detection
      final parsedData = _parseWithColumnDetection(recognizedText);

      // Store original OCR text
      parsedData['ocrRawText'] = recognizedText.text;

      return parsedData;
    } catch (e) {
      return {
        'licenseId': '',
        'fullName': '',
        'dateOfBirth': '',
        'expiryDate': '',
        'licenseType': '',
        'sex': '',
        'ocrRawText': 'OCR extraction failed: ${e.toString()}',
      };
    }
  }

  /// Normalize text for better pattern matching
  static String _normalize(String text) {
    return text
        .replaceAll(RegExp(r'[Oo]'), '0')
        .replaceAll(RegExp(r'[Il]'), '1')
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
  }

  /// Parse with left/right column detection
  static Map<String, String> _parseWithColumnDetection(
    RecognizedText recognizedText,
  ) {
    // Calculate image midpoint
    double maxX = 0;
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final box = line.boundingBox;
        if (box.right > maxX) {
          maxX = box.right;
        }
      }
    }
    final midX = maxX / 2;

    // Separate text into left and right columns
    List<String> leftColumn = [];
    List<String> rightColumn = [];
    List<String> leftColumnRaw = []; // Keep original case for grade extraction
    List<String> rightColumnRaw = []; // Keep original case for dates

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final box = line.boundingBox;

        if (box.left < midX) {
          leftColumn.add(line.text);
          leftColumnRaw.add(line.text);
        } else {
          rightColumn.add(line.text);
          rightColumnRaw.add(line.text);
        }
      }
    }

    final leftText = _normalize(leftColumn.join(" "));
    final rightText = _normalize(rightColumn.join(" "));
    final leftTextRaw = leftColumnRaw.join(" ");
    final rightTextRaw = rightColumnRaw.join(" ");
    final rawText = recognizedText.text;

    return {
      'licenseId': _extractLicense(leftText, leftTextRaw) ?? '',
      'fullName': _extractName(rawText) ?? '',
      'dateOfBirth': _extractDOB(rightText, rightTextRaw) ?? '',
      'expiryDate': _extractExpiry(rightText, rightTextRaw) ?? '',
      'licenseType': _extractGrade(leftTextRaw) ?? '',
      'sex': '',
      'address': '',
    };
  }

  /// Extract 6-digit license number only
  static String? _extractLicense(String normalizedText, String rawText) {
    // First try to find 6 consecutive digits in normalized text
    final match = RegExp(r'\b(\d{6})\b').firstMatch(normalizedText);
    if (match != null) {
      return match.group(1);
    }

    // Try in raw text as well
    final rawMatch = RegExp(r'\b(\d{6})\b').firstMatch(rawText);
    if (rawMatch != null) {
      return rawMatch.group(1);
    }

    // Look for 6 digits with possible spaces or separators
    final spacedMatch = RegExp(
      r'(\d)\s*(\d)\s*(\d)\s*(\d)\s*(\d)\s*(\d)',
    ).firstMatch(normalizedText);
    if (spacedMatch != null) {
      return '${spacedMatch.group(1)}${spacedMatch.group(2)}${spacedMatch.group(3)}'
          '${spacedMatch.group(4)}${spacedMatch.group(5)}${spacedMatch.group(6)}';
    }

    return null;
  }

  /// Extract full name (all caps, 10+ characters)
  static String? _extractName(String raw) {
    for (var line in raw.split('\n')) {
      final trimmed = line.trim();
      if (RegExp(r'^[A-Z ]{10,}$').hasMatch(trimmed)) {
        return trimmed;
      }
    }
    return null;
  }

  /// Extract date of birth from right column
  static String? _extractDOB(String normalizedText, String rawText) {
    // Try multiple date patterns

    // Pattern 1: DD/MM/YYYY or DD MM YYYY
    var match = RegExp(
      r'\b(\d{1,2})[\s/\-](\d{1,2})[\s/\-](19\d{2}|20\d{2})\b',
    ).firstMatch(rawText);

    if (match != null) {
      final day = match.group(1)!.padLeft(2, '0');
      final month = match.group(2)!.padLeft(2, '0');
      final year = match.group(3)!;
      return '$year-$month-$day';
    }

    // Pattern 2: Look in normalized text
    match = RegExp(
      r'\b(\d{1,2})[\s/\-](\d{1,2})[\s/\-](19\d{2}|20\d{2})\b',
    ).firstMatch(normalizedText);

    if (match != null) {
      final day = match.group(1)!.padLeft(2, '0');
      final month = match.group(2)!.padLeft(2, '0');
      final year = match.group(3)!;
      return '$year-$month-$day';
    }

    // Pattern 3: Spaced digits like "1 5 1990"
    match = RegExp(
      r'(\d{1,2})\s+(\d{1,2})\s+(19\d{2}|20\d{2})',
    ).firstMatch(rawText);

    if (match != null) {
      final day = match.group(1)!.padLeft(2, '0');
      final month = match.group(2)!.padLeft(2, '0');
      final year = match.group(3)!;
      return '$year-$month-$day';
    }

    return null;
  }

  /// Extract expiry date (last date found in right column)
  static String? _extractExpiry(String normalizedText, String rawText) {
    // Find all dates in the right column
    final matches = RegExp(
      r'\b(\d{1,2})[\s/\-,](\d{1,2})[\s/\-,](20\d{2})\b',
    ).allMatches(rawText).toList();

    if (matches.isEmpty) {
      // Try normalized text
      final normalizedMatches = RegExp(
        r'\b(\d{1,2})[\s/\-,](\d{1,2})[\s/\-,](20\d{2})\b',
      ).allMatches(normalizedText).toList();

      if (normalizedMatches.isEmpty) return null;

      // Take the last date (expiry is usually after DOB)
      final match = normalizedMatches.last;
      final day = match.group(1)!.padLeft(2, '0');
      final month = match.group(2)!.padLeft(2, '0');
      final year = match.group(3)!;
      return '$year-$month-$day';
    }

    // Take the last date found (usually expiry is after DOB)
    final match = matches.last;
    final day = match.group(1)!.padLeft(2, '0');
    final month = match.group(2)!.padLeft(2, '0');
    final year = match.group(3)!;
    return '$year-$month-$day';
  }

  /// Extract grade (word after "Grade" or "grade")
  /// Valid types: Auto, Public 1, Public 2, 02, Taxi 1, Taxi 2
  static String? _extractGrade(String rawText) {
    // Define valid license types
    const validTypes = [
      'Auto',
      'Public 1',
      'Public 2',
      '02',
      'Taxi 1',
      'Taxi 2',
    ];

    // Look for "Grade" followed by text
    final gradeMatch = RegExp(
      r'grade[\s:]*([a-zA-Z0-9\s]+)',
      caseSensitive: false,
    ).firstMatch(rawText);

    String? extractedText;
    if (gradeMatch != null) {
      extractedText = gradeMatch.group(1)!.trim();
    } else {
      // If no "Grade" keyword, search entire text
      extractedText = rawText;
    }

    // Normalize extracted text for comparison
    final normalized = extractedText.toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    // Try exact matches first (case-insensitive)
    for (final type in validTypes) {
      if (normalized.contains(type.toLowerCase())) {
        return type;
      }
    }

    // Try fuzzy matching for common OCR errors

    // Auto variations
    if (normalized.contains('auto') ||
        normalized.contains('aut0') ||
        normalized.contains('aulo')) {
      return 'Auto';
    }

    // Public 1 variations
    if ((normalized.contains('public') && normalized.contains('1')) ||
        normalized.contains('public1') ||
        normalized.contains('pub1ic 1') ||
        normalized.contains('publ1c 1')) {
      return 'Public 1';
    }

    // Public 2 variations
    if ((normalized.contains('public') && normalized.contains('2')) ||
        normalized.contains('public2') ||
        normalized.contains('pub1ic 2') ||
        normalized.contains('publ1c 2')) {
      return 'Public 2';
    }

    // 02 variations
    if (normalized.contains('02') ||
        normalized.contains('o2') ||
        normalized.contains('0 2')) {
      return '02';
    }

    // Taxi 1 variations
    if ((normalized.contains('taxi') && normalized.contains('1')) ||
        normalized.contains('taxi1') ||
        normalized.contains('tax1 1') ||
        normalized.contains('taxl 1')) {
      return 'Taxi 1';
    }

    // Taxi 2 variations
    if ((normalized.contains('taxi') && normalized.contains('2')) ||
        normalized.contains('taxi2') ||
        normalized.contains('tax1 2') ||
        normalized.contains('taxl 2')) {
      return 'Taxi 2';
    }

    // Fallback: Check if any valid type appears in the text
    for (final type in validTypes) {
      final typeWords = type.toLowerCase().split(' ');
      bool allWordsFound = true;

      for (final word in typeWords) {
        if (!normalized.contains(word)) {
          allWordsFound = false;
          break;
        }
      }

      if (allWordsFound) {
        return type;
      }
    }

    // Last resort: Return first valid type found in text
    if (normalized.contains('auto')) return 'Auto';
    if (normalized.contains('public')) return 'Public 1'; // Default to Public 1
    if (normalized.contains('taxi')) return 'Taxi 1'; // Default to Taxi 1
    if (normalized.contains('02') || normalized.contains('o2')) return '02';

    return null;
  }

  /// Parse QR code data
  /// Supports both Amharic text format and pipe-separated format
  static Map<String, String> parseQRData(String qrData) {
    final result = <String, String>{
      'licenseId': '',
      'fullName': '',
      'dateOfBirth': '',
      'address': '',
      'licenseType': '',
      'issueDate': '',
      'expiryDate': '',
      'qrRawData': qrData, // Store raw QR data exactly as received
      'ocrRawText': qrData,
    };

    try {
      // PRIORITY 1: Check for Amharic QR format
      // Format: "የአሽከርካሪው ስም :-<name>የመንጃ ፍቃድ ቁጥር :-<license_id>"
      if (qrData.contains('የአሽከርካሪው') || qrData.contains('የመንጃ')) {
        // Extract full license string
        final licensePattern = RegExp(
          r'የመንጃ\s*ፍቃድ\s*ቁጥር\s*[:\-\s]*(.+)',
          caseSensitive: false,
          multiLine: true,
        );
        final licenseMatch = licensePattern.firstMatch(qrData);
        if (licenseMatch != null && licenseMatch.group(1) != null) {
          final fullLicenseString = licenseMatch.group(1)!.trim();

          // Parse Amharic license format: Region-Grade-LicenseNumber
          final licenseParts = fullLicenseString.split('-');

          if (licenseParts.length == 3) {
            result['licenseId'] = licenseParts[2].trim(); // License Number
            result['licenseType'] = licenseParts[1].trim(); // Grade
            result['address'] = licenseParts[0].trim(); // Region
          } else {
            result['licenseId'] = fullLicenseString;
          }
        }

        // Extract Name
        final namePattern = RegExp(
          r'የአሽከርካሪው\s*ስም\s*[:\-\s]*(.+?)የመንጃ\s*ፍቃድ\s*ቁጥር',
          caseSensitive: false,
          multiLine: true,
        );
        final nameMatch = namePattern.firstMatch(qrData);
        if (nameMatch != null && nameMatch.group(1) != null) {
          result['fullName'] = nameMatch.group(1)!.trim();
        }

        return result;
      }

      // PRIORITY 2: Try pipe-separated format
      final parts = qrData.split('|');
      if (parts.length >= 7) {
        return {
          'licenseId': parts[0].trim(),
          'fullName': parts[1].trim(),
          'dateOfBirth': parts[2].trim(),
          'address': parts[3].trim(),
          'licenseType': parts[4].trim(),
          'issueDate': parts[5].trim(),
          'expiryDate': parts[6].trim(),
          'qrRawData': qrData,
        };
      }
    } catch (e) {
      // Return result with raw data if parsing fails
    }

    return result;
  }

  /// Normalize license ID
  static String normalizeLicenseId(String licenseId) {
    return licenseId.trim().toUpperCase();
  }

  /// Generate QR data string from driver info
  static String generateQRData(Map<String, String> driverData) {
    return '${driverData['licenseId']}|'
        '${driverData['fullName']}|'
        '${driverData['dateOfBirth']}|'
        '${driverData['address']}|'
        '${driverData['licenseType']}|'
        '${driverData['issueDate']}|'
        '${driverData['expiryDate']}';
  }

  /// Dispose resources
  static void dispose() {
    _textRecognizer.close();
  }
}
