import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/document_scanner_service.dart';
import '../services/ocr_service.dart';

/// Document Scanner Screen
///
/// Provides UI for:
/// - Scanning driver license with camera
/// - Selecting image from gallery
/// - Previewing scanned/processed image
/// - Extracting text via OCR
/// - Displaying extracted data
class DocumentScannerScreen extends StatefulWidget {
  const DocumentScannerScreen({super.key});

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
  String? _scannedImagePath;
  Map<String, String>? _extractedData;
  bool _isProcessing = false;
  String? _errorMessage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Clean up old temporary files on screen load
    DocumentScannerService.cleanupTempFiles();
  }

  /// Scan document using camera with edge detection
  Future<void> _scanWithCamera() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _scannedImagePath = null;
      _extractedData = null;
    });

    try {
      // Launch document scanner
      final imagePath = await DocumentScannerService.scanDocument();

      if (imagePath != null) {
        // Validate the scanned image
        final isValid = await DocumentScannerService.validateImage(imagePath);

        if (!isValid) {
          setState(() {
            _errorMessage = 'Image quality is too low. Please scan again.';
            _isProcessing = false;
          });
          return;
        }

        setState(() {
          _scannedImagePath = imagePath;
        });

        // Automatically run OCR on the scanned image
        await _runOCR();
      } else {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Scanning failed: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }

  /// Pick image from gallery and apply edge detection
  Future<void> _pickFromGallery() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _scannedImagePath = null;
      _extractedData = null;
    });

    try {
      // Pick image from gallery
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (pickedFile != null) {
        // Apply edge detection to the picked image
        final processedPath = await DocumentScannerService.scanFromImage(
          pickedFile.path,
        );

        if (processedPath != null) {
          // Validate the processed image
          final isValid = await DocumentScannerService.validateImage(
            processedPath,
          );

          if (!isValid) {
            setState(() {
              _errorMessage =
                  'Image quality is too low. Please try another image.';
              _isProcessing = false;
            });
            return;
          }

          setState(() {
            _scannedImagePath = processedPath;
          });

          // Automatically run OCR
          await _runOCR();
        } else {
          setState(() {
            _isProcessing = false;
          });
        }
      } else {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to process image: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }

  /// Run OCR on the scanned image
  Future<void> _runOCR() async {
    if (_scannedImagePath == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Extract data using OCR
      final data = await OCRService.extractDataFromImage(_scannedImagePath!);

      setState(() {
        _extractedData = data;
        _isProcessing = false;
      });

      // Check if OCR extracted any meaningful data
      final hasData = data.values.any(
        (value) => value.isNotEmpty && value != 'OCR extraction failed',
      );

      if (!hasData) {
        setState(() {
          _errorMessage =
              'Could not extract data. Please ensure the license is clearly visible.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'OCR failed: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }

  /// Clear current scan and start over
  void _clearScan() {
    setState(() {
      _scannedImagePath = null;
      _extractedData = null;
      _errorMessage = null;
      _isProcessing = false;
    });
  }

  /// Navigate back with extracted data
  void _confirmAndReturn() {
    if (_extractedData != null) {
      Navigator.pop(context, {
        'imagePath': _scannedImagePath,
        'extractedData': _extractedData,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Driver License'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          if (_scannedImagePath != null && _extractedData != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _confirmAndReturn,
              tooltip: 'Confirm and Use Data',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isProcessing) {
      return _buildLoadingView();
    }

    if (_scannedImagePath != null) {
      return _buildResultView();
    }

    return _buildInitialView();
  }

  /// Initial view with scan options
  Widget _buildInitialView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.document_scanner, size: 120, color: Colors.blue[300]),
            const SizedBox(height: 32),
            const Text(
              'Scan Driver License',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Capture a clear photo of the driver license.\nThe app will automatically detect edges and enhance the image.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 48),

            // Scan with Camera button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _scanWithCamera,
                icon: const Icon(Icons.camera_alt, size: 28),
                label: const Text(
                  'Scan with Camera',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Pick from Gallery button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library, size: 28),
                label: const Text(
                  'Choose from Gallery',
                  style: TextStyle(fontSize: 18),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                  side: BorderSide(color: Colors.blue[700]!, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Loading view during processing
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            _scannedImagePath == null
                ? 'Processing image...'
                : 'Extracting text...',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Result view showing scanned image and extracted data
  Widget _buildResultView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Scanned image preview
          Container(
            height: 300,
            color: Colors.grey[200],
            child: _scannedImagePath != null
                ? Image.file(File(_scannedImagePath!), fit: BoxFit.contain)
                : const Center(child: Icon(Icons.image, size: 64)),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearScan,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Scan Again'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _extractedData != null ? _runOCR : null,
                    icon: const Icon(Icons.text_fields),
                    label: const Text('Re-run OCR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Error message
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.orange[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Extracted data
          if (_extractedData != null) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Extracted Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            _buildDataCard('License ID', _extractedData!['licenseId']),
            _buildDataCard('Full Name', _extractedData!['fullName']),
            _buildDataCard('Date of Birth', _extractedData!['dateOfBirth']),
            _buildDataCard('Expiry Date', _extractedData!['expiryDate']),
            _buildDataCard('License Type', _extractedData!['licenseType']),
            _buildDataCard('Sex', _extractedData!['sex']),
            _buildDataCard('Address', _extractedData!['address']),

            // Raw OCR text (collapsible)
            if (_extractedData!['ocrRawText']?.isNotEmpty ?? false)
              ExpansionTile(
                title: const Text('Raw OCR Text'),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[100],
                    child: Text(
                      _extractedData!['ocrRawText'] ?? '',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

            // Confirm button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _confirmAndReturn,
                  icon: const Icon(Icons.check_circle, size: 28),
                  label: const Text(
                    'Use This Data',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build a data card for displaying extracted field
  Widget _buildDataCard(String label, String? value) {
    final hasValue = value != null && value.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          hasValue ? Icons.check_circle : Icons.cancel,
          color: hasValue ? Colors.green : Colors.red,
        ),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          hasValue ? value : 'Not detected',
          style: TextStyle(
            fontSize: 16,
            color: hasValue ? Colors.black87 : Colors.grey,
          ),
        ),
      ),
    );
  }
}
