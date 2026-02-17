import 'package:flutter/material.dart';
import '../screens/document_scanner_screen.dart';
import '../services/document_scanner_service.dart';
import '../services/ocr_service.dart';

/// Example demonstrating how to integrate the document scanner
/// into your existing driver registration flow
class ScannerIntegrationExample extends StatefulWidget {
  const ScannerIntegrationExample({super.key});

  @override
  State<ScannerIntegrationExample> createState() =>
      _ScannerIntegrationExampleState();
}

class _ScannerIntegrationExampleState extends State<ScannerIntegrationExample> {
  Map<String, String>? _driverData;
  String? _scannedImagePath;

  /// EXAMPLE 1: Navigate to scanner screen and get results
  Future<void> _openScannerScreen() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const DocumentScannerScreen()),
    );

    if (result != null) {
      setState(() {
        _scannedImagePath = result['imagePath'] as String?;
        _driverData = result['extractedData'] as Map<String, String>?;
      });

      // Now you can use the extracted data
      _processExtractedData();
    }
  }

  /// EXAMPLE 2: Use scanner service directly (without UI)
  Future<void> _scanDirectly() async {
    try {
      // Scan document
      final imagePath = await DocumentScannerService.scanDocument();

      if (imagePath != null) {
        // Validate image
        final isValid = await DocumentScannerService.validateImage(imagePath);

        if (isValid) {
          // Run OCR
          final extractedData = await OCRService.extractDataFromImage(
            imagePath,
          );

          setState(() {
            _scannedImagePath = imagePath;
            _driverData = extractedData;
          });

          _processExtractedData();
        } else {
          _showError('Image quality is too low');
        }
      }
    } catch (e) {
      _showError('Scanning failed: $e');
    }
  }

  /// EXAMPLE 3: Process existing image with edge detection
  Future<void> _processExistingImage(String existingImagePath) async {
    try {
      // Apply edge detection to existing image
      final processedPath = await DocumentScannerService.scanFromImage(
        existingImagePath,
      );

      if (processedPath != null) {
        // Run OCR on processed image
        final extractedData = await OCRService.extractDataFromImage(
          processedPath,
        );

        setState(() {
          _scannedImagePath = processedPath;
          _driverData = extractedData;
        });

        _processExtractedData();
      }
    } catch (e) {
      _showError('Processing failed: $e');
    }
  }

  /// Process the extracted data
  void _processExtractedData() {
    if (_driverData == null) return;

    // Validate extracted data
    final licenseId = _driverData!['licenseId'] ?? '';
    final fullName = _driverData!['fullName'] ?? '';
    final dateOfBirth = _driverData!['dateOfBirth'] ?? '';

    if (licenseId.isEmpty || fullName.isEmpty) {
      _showError('Could not extract required fields. Please try again.');
      return;
    }

    // Data is valid - proceed with your business logic
    // For example:
    // - Save to database
    // - Navigate to confirmation screen
    // - Send to backend API

    _showSuccess('Data extracted successfully!');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner Integration Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Integration Examples',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Example 1: Full UI screen
            ElevatedButton(
              onPressed: _openScannerScreen,
              child: const Text('Example 1: Open Scanner Screen (Recommended)'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Opens a full-featured scanner screen with preview and OCR',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

            const SizedBox(height: 24),

            // Example 2: Direct service call
            ElevatedButton(
              onPressed: _scanDirectly,
              child: const Text('Example 2: Use Scanner Service Directly'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Programmatic scanning without the full UI',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

            const SizedBox(height: 32),

            // Display extracted data
            if (_driverData != null) ...[
              const Divider(),
              const Text(
                'Extracted Data:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildDataRow('License ID', _driverData!['licenseId']),
              _buildDataRow('Full Name', _driverData!['fullName']),
              _buildDataRow('Date of Birth', _driverData!['dateOfBirth']),
              _buildDataRow('Expiry Date', _driverData!['expiryDate']),
              _buildDataRow('License Type', _driverData!['licenseType']),
              _buildDataRow('Sex', _driverData!['sex']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value ?? 'Not detected')),
        ],
      ),
    );
  }
}
