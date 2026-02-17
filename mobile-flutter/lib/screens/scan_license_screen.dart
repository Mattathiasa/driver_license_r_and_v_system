import 'dart:io';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import '../services/ocr_service.dart';
import 'register_driver_screen.dart';

class ScanLicenseScreen extends StatefulWidget {
  const ScanLicenseScreen({super.key});

  @override
  State<ScanLicenseScreen> createState() => _ScanLicenseScreenState();
}

class _ScanLicenseScreenState extends State<ScanLicenseScreen> {
  String? _scannedImagePath;
  bool _isProcessing = false;
  Map<String, String>? _extractedData;

  Future<void> _scanDocument() async {
    try {
      // Use cunning_document_scanner for edge detection and perspective correction
      List<String> pictures =
          await CunningDocumentScanner.getPictures(
            noOfPages: 1, // Only scan one page (the license)
          ) ??
          [];

      if (pictures.isNotEmpty) {
        setState(() {
          _scannedImagePath = pictures.first;
          _extractedData = null;
        });
        await _processImage();
      }
    } catch (e) {
      _showError('Failed to scan document: ${e.toString()}');
    }
  }

  Future<void> _processImage() async {
    if (_scannedImagePath == null) return;

    setState(() => _isProcessing = true);

    try {
      // Real OCR extraction using Google ML Kit
      final data = await OCRService.extractDataFromImage(_scannedImagePath!);

      // Debug: Print extracted data
      debugPrint('=== OCR Extracted Data ===');
      debugPrint('License ID: ${data['licenseId']}');
      debugPrint('Full Name: ${data['fullName']}');
      debugPrint('Date of Birth: ${data['dateOfBirth']}');
      debugPrint('License Type: ${data['licenseType']}');
      debugPrint('Expiry Date: ${data['expiryDate']}');
      debugPrint('OCR Raw Text: ${data['ocrRawText']}');
      debugPrint('========================');

      final qrData = OCRService.generateQRData(data);
      data['qrRawData'] = qrData;

      setState(() {
        _extractedData = data;
        _isProcessing = false;
      });

      // Automatically navigate to registration screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RegisterDriverScreen(
              prefilledData: data,
              imagePath: _scannedImagePath,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      debugPrint('OCR Error: $e');
      _showError('Failed to process image: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: GoogleFonts.outfit())),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _proceedToRegistration() {
    if (_extractedData == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterDriverScreen(
          prefilledData: _extractedData!,
          imagePath: _scannedImagePath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo.shade700,
              Colors.indigo.shade600,
              const Color(0xFFF8FAFC),
            ],
            stops: const [0.0, 0.15, 0.15],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    FadeInLeft(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FadeIn(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Scan License',
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Auto-detect edges & extract data',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Instructions
                      FadeInUp(
                        delay: const Duration(milliseconds: 100),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.indigo.shade100),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: Colors.indigo.shade700,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      'Smart Document Scanner',
                                      style: GoogleFonts.outfit(
                                        color: Colors.indigo.shade900,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '• Automatic edge detection\n'
                                '• Manual corner adjustment\n'
                                '• Perspective correction\n'
                                '• OCR text extraction',
                                style: GoogleFonts.outfit(
                                  color: Colors.indigo.shade800,
                                  fontSize: 14,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Scan Button
                      FadeInUp(
                        delay: const Duration(milliseconds: 200),
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : _scanDocument,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 5,
                            shadowColor: Colors.indigo.withValues(alpha: 0.3),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.document_scanner_rounded,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Scan Driver License',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Image Preview
                      if (_scannedImagePath != null)
                        FadeIn(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(
                                File(_scannedImagePath!),
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),

                      if (_scannedImagePath != null) const SizedBox(height: 32),

                      // Processing Indicator
                      if (_isProcessing)
                        FadeIn(
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                CircularProgressIndicator(
                                  color: Colors.indigo.shade700,
                                  strokeWidth: 3,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Processing image...',
                                  style: GoogleFonts.outfit(
                                    color: Colors.indigo.shade900,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Extracting license data using OCR',
                                  style: GoogleFonts.outfit(
                                    color: Colors.blueGrey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Extracted Data
                      if (_extractedData != null && !_isProcessing)
                        FadeInUp(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.teal.shade600,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Extraction Complete',
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 32),

                                _DataRow(
                                  label: 'License ID Number',
                                  value: _extractedData!['licenseId'] ?? '',
                                  icon: Icons.badge_rounded,
                                ),
                                _DataRow(
                                  label: 'Full Name',
                                  value: _extractedData!['fullName'] ?? '',
                                  icon: Icons.person_rounded,
                                ),
                                _DataRow(
                                  label: 'Date of Birth',
                                  value: _extractedData!['dateOfBirth'] ?? '',
                                  icon: Icons.cake_rounded,
                                ),
                                _DataRow(
                                  label: 'Grade',
                                  value: _extractedData!['licenseType'] ?? '',
                                  icon: Icons.stars_rounded,
                                ),
                                _DataRow(
                                  label: 'Expiry Date',
                                  value: _extractedData!['expiryDate'] ?? '',
                                  icon: Icons.event_rounded,
                                ),
                                _DataRow(
                                  label: 'QR Raw Data',
                                  value: _extractedData!['qrRawData'] ?? '',
                                  icon: Icons.qr_code_rounded,
                                  isExpandable: true,
                                ),
                                _DataRow(
                                  label: 'OCR Raw Text',
                                  value: _extractedData!['ocrRawText'] ?? '',
                                  icon: Icons.text_fields_rounded,
                                  isExpandable: true,
                                ),

                                const SizedBox(height: 24),

                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _proceedToRegistration,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal.shade600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 5,
                                      shadowColor: Colors.teal.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.arrow_forward_rounded),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Proceed to Registration',

                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper widget for displaying extracted data
class _DataRow extends StatefulWidget {
  final String label;
  final String value;
  final IconData? icon;
  final bool isExpandable;

  const _DataRow({
    required this.label,
    required this.value,
    this.icon,
    this.isExpandable = false,
  });

  @override
  State<_DataRow> createState() => _DataRowState();
}

class _DataRowState extends State<_DataRow> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final displayValue = widget.value.isEmpty ? '-' : widget.value;
    final shouldTruncate =
        widget.isExpandable && displayValue.length > 50 && !_isExpanded;
    final truncatedValue = shouldTruncate
        ? '${displayValue.substring(0, 50)}...'
        : displayValue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: Colors.indigo.shade600),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blueGrey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  truncatedValue,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.blueGrey.shade900,
                    height: 1.4,
                  ),
                ),
                if (widget.isExpandable && displayValue.length > 50)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                    ),
                    label: Text(
                      _isExpanded ? 'Show less' : 'Show more',
                      style: GoogleFonts.outfit(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
