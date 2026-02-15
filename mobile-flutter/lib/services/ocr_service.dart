import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  static final _textRecognizer = TextRecognizer();

  /// Extract text from image using Google ML Kit
  /// Returns: License ID, Full Name, Date of Birth, Expiry Date, OCR raw text
  static Future<Map<String, String>> extractDataFromImage(
    String imagePath,
  ) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final fullText = recognizedText.text;

      // Parse the recognized text to extract license fields
      final parsedData = _parseDriverLicenseText(fullText);

      // Ensure OCR raw text is always included
      parsedData['ocrRawText'] = fullText;

      return parsedData;
    } catch (e) {
      // If OCR fails, return empty data
      return {
        'licenseId': '',
        'fullName': '',
        'dateOfBirth': '',
        'expiryDate': '',
        'ocrRawText': 'OCR extraction failed: ${e.toString()}',
      };
    }
  }

  /// Parse driver license text to extract specific fields
  static Map<String, String> _parseDriverLicenseText(String text) {
    final data = <String, String>{
      'licenseId': '',
      'fullName': '',
      'dateOfBirth': '',
      'address': '',
      'licenseType': '',
      'issueDate': '',
      'expiryDate': '',
      'ocrRawText': text,
    };

    final lines = text.split('\n');

    // PRIORITY 1: Extract License ID and Name from Amharic QR format
    // Full text format: "የአሽከርካሪው ስም :-<name>የመንጃ ፍቃድ ቁጥር :-<license_id>"
    // Example 1: "የአሽከርካሪው ስም :-ማታቲያስ አብርሃምየመንጃ ፍቃድ ቁጥር :-አዲስ አበባ-አውቶ-379171"
    // Example 2: "የአሽከርካሪው ስም :-አብርሃም በላይነህየመንጃ ፍቃድ ቁጥር :-አዲስ አበባ-አውቶ-026016"

    // Extract License ID: from "የመንጃ ፍቃድ ቁጥር :-" to end of text
    final amharicLicensePattern = RegExp(
      r'የመንጃ\s*ፍቃድ\s*ቁጥር\s*[:\-\s]*(.+)$',
      caseSensitive: false,
      multiLine: true,
    );
    final amharicLicenseMatch = amharicLicensePattern.firstMatch(text);
    if (amharicLicenseMatch != null && amharicLicenseMatch.group(1) != null) {
      final fullLicenseString = amharicLicenseMatch.group(1)!.trim();

      // Parse Amharic license format: Region-Grade-LicenseNumber
      final licenseParts = fullLicenseString.split('-');
      if (licenseParts.length == 3) {
        data['licenseId'] = licenseParts[2].trim(); // License Number
        data['licenseType'] = licenseParts[1].trim(); // Grade
        data['address'] = licenseParts[0].trim(); // Region
      } else {
        data['licenseId'] = fullLicenseString;
      }
    }

    // Extract Name: text between "የአሽከርካሪው ስም :-" and "የመንጃ ፍቃድ ቁጥር :-"
    final amharicNamePattern = RegExp(
      r'የአሽከርካሪው\s*ስም\s*[:\-\s]*(.+?)የመንጃ\s*ፍቃድ\s*ቁጥር',
      caseSensitive: false,
      multiLine: true,
    );
    final amharicNameMatch = amharicNamePattern.firstMatch(text);
    if (amharicNameMatch != null && amharicNameMatch.group(1) != null) {
      data['fullName'] = amharicNameMatch.group(1)!.trim();
    }

    // PRIORITY 2: If no Amharic pattern found, extract 6-digit license ID
    if (data['licenseId']!.isEmpty) {
      // Extract 6-digit license ID
      final licenseIdPatterns = [
        // License ID with keyword: LICENSE NO: 123456, DL: 123456
        RegExp(
          r'(?:LICENSE|DL|LIC)\s*(?:NO|NUMBER|ID)?\s*[:\-]?\s*(\d{6})',
          caseSensitive: false,
        ),

        // Standalone 6-digit number
        RegExp(r'\b(\d{6})\b'),
      ];

      for (final pattern in licenseIdPatterns) {
        final match = pattern.firstMatch(text);
        if (match != null && match.group(1) != null) {
          final digits = match.group(1)!.trim();
          // Verify it's not part of a date
          if (!text.contains(RegExp('$digits[/-]')) &&
              !text.contains(RegExp('[/-]$digits'))) {
            data['licenseId'] = digits;
            break;
          }
        }
      }
    }

    // PRIORITY 2: If no Amharic name found already, try English patterns
    if (data['fullName']!.isEmpty) {
      // Extract Name (usually after "NAME" keyword)
      final namePatterns = [
        RegExp(r'NAME\s*[:\-]?\s*([A-Z\s]{3,50})', caseSensitive: false),
        RegExp(r'FULL\s*NAME\s*[:\-]?\s*([A-Z\s]{3,50})', caseSensitive: false),
      ];

      for (final pattern in namePatterns) {
        final match = pattern.firstMatch(text);
        if (match != null && match.group(1) != null) {
          data['fullName'] = match.group(1)!.trim();
          break;
        }
      }
    }

    // Fallback Name: if name is empty, try to find a long Uppercase line or Amharic text
    if (data['fullName']!.isEmpty) {
      for (var line in lines) {
        final trimmed = line.trim();
        // Check for English uppercase names
        if (trimmed.length > 8 &&
            RegExp(r'^[A-Z ]+$').hasMatch(trimmed) &&
            !trimmed.contains('LICENSE') &&
            !trimmed.contains('IDENTITY')) {
          data['fullName'] = trimmed;
          break;
        }
        // Check for Amharic names (longer sequences of Amharic characters)
        if (trimmed.length > 6 &&
            RegExp(r'^[\u1200-\u137F\s]+$').hasMatch(trimmed) &&
            !trimmed.contains('የመንጃ') &&
            !trimmed.contains('የአሽከርካሪው')) {
          data['fullName'] = trimmed;
          break;
        }
      }
    }

    // Extract Date of Birth (Ethiopian license format)
    // Format: DOB keyword followed by two lines of numbers
    // Line 1: Gregorian (Month Day Year) e.g., "3 8 2001"
    // Line 2: Ethiopian (Day Month Year) e.g., "30 8 1993"
    if (data['dateOfBirth']!.isEmpty) {
      final dobMatch = _extractEthiopianDate(text, 'DOB');
      if (dobMatch != null) {
        data['dateOfBirth'] = dobMatch;
      }
    }

    // Extract Expiry Date (Ethiopian license format)
    if (data['expiryDate']!.isEmpty) {
      final expiryMatch = _extractEthiopianDate(text, 'EXPIRY|EXP|EXPIRES');
      if (expiryMatch != null) {
        data['expiryDate'] = expiryMatch;
      }
    }

    // Extract License Type (A, B, C, D, E, etc.)
    final typePatterns = [
      RegExp(
        r'(?:CLASS|TYPE|CATEGORY)\s*[:\-]?\s*([A-E])',
        caseSensitive: false,
      ),
      RegExp(r'LICENSE\s*TYPE\s*[:\-]?\s*([A-E])', caseSensitive: false),
    ];

    for (final pattern in typePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        data['licenseType'] = match.group(1)!.toUpperCase();
        break;
      }
    }

    // Extract Issue Date
    final issueDatePatterns = [
      RegExp(
        r'(?:ISSUE|ISSUED)\s*(?:DATE)?\s*[:\-]?\s*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})',
        caseSensitive: false,
      ),
    ];

    for (final pattern in issueDatePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        data['issueDate'] = _formatDate(match.group(1)!);
        break;
      }
    }

    // Extract Expiry Date
    final expiryDatePatterns = [
      RegExp(
        r'(?:EXPIRY|EXPIRES|EXPIRATION|VALID\s*UNTIL)\s*(?:DATE)?\s*[:\-]?\s*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})',
        caseSensitive: false,
      ),
      RegExp(
        r'EXP\s*[:\-]?\s*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})',
        caseSensitive: false,
      ),
    ];

    for (final pattern in expiryDatePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        data['expiryDate'] = _formatDate(match.group(1)!);
        break;
      }
    }

    // Extract Address (usually multi-line, after ADDRESS keyword)
    final addressPattern = RegExp(
      r'(?:ADDRESS|ADD|LOC)\s*[:\-]?\s*([A-Z0-9\s,\.]{10,150})',
      caseSensitive: false,
    );
    final addressMatch = addressPattern.firstMatch(text.replaceAll('\n', ' '));
    if (addressMatch != null && addressMatch.group(1) != null) {
      data['address'] = addressMatch.group(1)!.trim();
    }

    return data;
  }

  /// Extract Ethiopian license date format
  /// Format on Ethiopian license:
  /// Line 1: Keyword (DOB or EXPIRY)
  /// Line 2: Concatenated digits (e.g., 382001)
  /// Line 3: Spaced Gregorian date (e.g., 3 8 2001) - Month Day Year
  /// Line 4: Ethiopian date (e.g., 30 8 1993) - Day Month Year
  /// We extract the Gregorian date from Line 3
  static String? _extractEthiopianDate(String text, String keyword) {
    try {
      final lines = text.split('\n');

      // Find the line containing the keyword
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim().toUpperCase();

        // Check if this line contains the keyword
        final keywordPattern = RegExp(keyword, caseSensitive: false);
        if (keywordPattern.hasMatch(line)) {
          // Look for the Gregorian date in the next 3 lines
          // Format: "Month Day Year" with spaces (e.g., "3 8 2001")
          for (int j = i + 1; j < lines.length && j <= i + 3; j++) {
            final dateLine = lines[j].trim();

            // Pattern: space-separated date (Month Day Year)
            final datePattern = RegExp(r'^(\d{1,2})\s+(\d{1,2})\s+(\d{4})$');
            final match = datePattern.firstMatch(dateLine);

            if (match != null) {
              final month = int.parse(match.group(1)!);
              final day = int.parse(match.group(2)!);
              final year = int.parse(match.group(3)!);

              // Validate month and day ranges
              if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
                print(
                  'Extracted $keyword date: $year-$month-$day from line: "$dateLine"',
                );
                return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
              }
            }
          }
        }
      }

      print('Could not extract $keyword date from text');
    } catch (e) {
      print('Error extracting Ethiopian date: $e');
    }
    return null;
  }

  /// Format date to YYYY-MM-DD
  static String _formatDate(String date) {
    try {
      // Handle different date formats
      final cleaned = date.replaceAll(RegExp(r'[^\d\/\-]'), '');
      final parts = cleaned.split(RegExp(r'[\/\-]'));

      if (parts.length == 3) {
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2]);

        // Handle 2-digit years
        if (year < 100) {
          year += (year > 50) ? 1900 : 2000;
        }

        return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      // Return original if parsing fails
    }
    return date;
  }

  /// Normalize license ID (ensure it's 6 digits)
  static String normalizeLicenseId(String licenseId) {
    final cleaned = licenseId.trim();

    // Remove any non-digit characters
    final digitsOnly = cleaned.replaceAll(RegExp(r'\D'), '');

    // Ensure it's exactly 6 digits
    if (digitsOnly.length == 6) {
      return digitsOnly;
    }

    return cleaned;
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
      'qrRawData': qrData,
      'ocrRawText': qrData,
    };

    try {
      // PRIORITY 1: Check for Amharic QR format
      // Format: "የአሽከርካሪው ስም :-<name>የመንጃ ፍቃድ ቁጥር :-<license_id>"
      if (qrData.contains('የአሽከርካሪው') || qrData.contains('የመንጃ')) {
        // Extract full license string: from "የመንጃ ፍቃድ ቁጥር :-" to end of text
        final licensePattern = RegExp(
          r'የመንጃ\s*ፍቃድ\s*ቁጥር\s*[:\-\s]*(.+)$',
          caseSensitive: false,
          multiLine: true,
        );
        final licenseMatch = licensePattern.firstMatch(qrData);
        if (licenseMatch != null && licenseMatch.group(1) != null) {
          final fullLicenseString = licenseMatch.group(1)!.trim();

          // Parse Amharic license format: Region-Grade-LicenseNumber
          // Example: "አዲስ አበባ-አውቶ-379171"
          // Split by hyphen to get: [Region, Grade, LicenseNumber]
          final licenseParts = fullLicenseString.split('-');

          if (licenseParts.length == 3) {
            // Extract the parts
            final region = licenseParts[0].trim(); // "አዲስ አበባ" (Addis Ababa)
            final grade = licenseParts[1].trim(); // "አውቶ" (Auto)
            final licenseNumber = licenseParts[2].trim(); // "379171"

            // Store the actual license number as licenseId
            result['licenseId'] = licenseNumber;

            // Store the grade/class as licenseType
            result['licenseType'] = grade;

            // Optionally store region as address or in a custom field
            result['address'] = region;
          } else {
            // If format doesn't match expected pattern, store full string
            result['licenseId'] = fullLicenseString;
          }
        }

        // Extract Name: text between "የአሽከርካሪው ስም :-" and "የመንጃ ፍቃድ ቁጥር :-"
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

      // PRIORITY 2: Try pipe-separated format (legacy/standard QR codes)
      final parts = qrData.split('|');
      if (parts.length >= 7) {
        return {
          'licenseId': parts[0].trim(),
          'fullName': parts[1],
          'dateOfBirth': parts[2],
          'address': parts[3],
          'licenseType': parts[4],
          'issueDate': parts[5],
          'expiryDate': parts[6],
        };
      } else if (parts.length >= 4) {
        return {
          'licenseId': parts[0].trim(),
          'fullName': parts[1],
          'expiryDate': parts[2],
          'qrSignature': parts[3],
        };
      }
    } catch (e) {
      // Return empty if parsing fails
    }

    return result;
  }

  /// Dispose resources
  static void dispose() {
    _textRecognizer.close();
  }
}
