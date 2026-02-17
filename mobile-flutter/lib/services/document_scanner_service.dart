import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;

/// Service class for document scanning with image enhancement
/// 
/// This service provides:
/// - Camera capture for documents
/// - Gallery image selection
/// - Image enhancement for better OCR accuracy
/// - Integration with google_mlkit_text_recognition
class DocumentScannerService {
  static final ImagePicker _picker = ImagePicker();

  /// Scan a document using camera
  /// 
  /// This method:
  /// 1. Opens the camera
  /// 2. Captures the document
  /// 3. Applies image enhancement
  /// 4. Returns the processed image path
  /// 
  /// Returns: Path to the processed image file, or null if cancelled
  static Future<String?> scanDocument() async {
    try {
      // Capture image from camera
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo == null) {
        return null; // User cancelled
      }

      // Process and enhance the image
      final enhancedPath = await _enhanceImage(photo.path);
      return enhancedPath;
    } catch (e) {
      debugPrint('Document scanning error: $e');
      throw DocumentScannerException('Failed to scan document: ${e.toString()}');
    }
  }

  /// Scan document from gallery
  /// 
  /// Use this when you want to select an existing image from gallery
  /// 
  /// Returns: Path to the processed image, or null if cancelled
  static Future<String?> scanFromGallery() async {
    try {
      // Pick image from gallery
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image == null) {
        return null; // User cancelled
      }

      // Process and enhance the image
      final enhancedPath = await _enhanceImage(image.path);
      return enhancedPath;
    } catch (e) {
      debugPrint('Gallery selection error: $e');
      throw DocumentScannerException('Failed to select image: ${e.toString()}');
    }
  }

  /// Scan document from an existing image file
  /// 
  /// Use this when you already have an image path and want to apply
  /// image enhancement
  /// 
  /// [imagePath]: Path to the source image
  /// Returns: Path to the processed image, or null if processing fails
  static Future<String?> scanFromImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw DocumentScannerException('Image file not found');
      }

      final enhancedPath = await _enhanceImage(imagePath);
      return enhancedPath;
    } catch (e) {
      debugPrint('Image processing error: $e');
      throw DocumentScannerException('Failed to process image: ${e.toString()}');
    }
  }

  /// Show options dialog for scanning
  /// 
  /// Displays a dialog allowing user to choose between camera or gallery
  /// 
  /// [context]: BuildContext for showing dialog
  /// Returns: Path to the processed image, or null if cancelled
  static Future<String?> showScanOptions(BuildContext context) async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Scan Driver License'),
          content: const Text('Choose how to capture the document:'),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Photo'),
              onPressed: () async {
                Navigator.pop(dialogContext);
                final imagePath = await scanDocument();
                if (context.mounted) {
                  Navigator.pop(context, imagePath);
                }
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Choose from Gallery'),
              onPressed: () async {
                Navigator.pop(dialogContext);
                final imagePath = await scanFromGallery();
                if (context.mounted) {
                  Navigator.pop(context, imagePath);
                }
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ],
        );
      },
    );
  }

  /// Enhance image for better OCR accuracy
  /// 
  /// Applies:
  /// - Contrast enhancement
  /// - Sharpening
  /// - Brightness adjustment
  /// - Optional grayscale conversion
  /// 
  /// [imagePath]: Path to the input image
  /// Returns: Path to the enhanced image
  static Future<String> _enhanceImage(String imagePath) async {
    try {
      // Read the image
      final imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        return imagePath; // Return original if decoding fails
      }

      // Resize if image is too large (max 2000px on longest side)
      if (image.width > 2000 || image.height > 2000) {
        final maxDimension = image.width > image.height ? image.width : image.height;
        final scale = 2000 / maxDimension;
        image = img.copyResize(
          image,
          width: (image.width * scale).round(),
          height: (image.height * scale).round(),
          interpolation: img.Interpolation.linear,
        );
      }

      // Apply image enhancements
      
      // 1. Increase contrast for better text visibility
      image = img.adjustColor(
        image,
        contrast: 1.4, // Increase contrast by 40%
        brightness: 1.1, // Slight brightness boost
        saturation: 0.7, // Reduce saturation for clearer text
      );

      // 2. Apply sharpening to make text edges clearer
      image = img.convolution(
        image,
        filter: [
          0, -1, 0,
          -1, 5, -1,
          0, -1, 0,
        ],
      );

      // 3. Optional: Convert to grayscale for better OCR
      // Uncomment if you want black & white output
      // image = img.grayscale(image);

      // Save enhanced image
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final enhancedPath = path.join(
        directory.path,
        'enhanced_document_$timestamp.jpg',
      );

      final enhancedFile = File(enhancedPath);
      await enhancedFile.writeAsBytes(img.encodeJpg(image, quality: 95));

      debugPrint('Image enhanced and saved to: $enhancedPath');
      return enhancedPath;
    } catch (e) {
      debugPrint('Image enhancement error: $e');
      // Return original path if enhancement fails
      return imagePath;
    }
  }

  /// Get image dimensions
  /// 
  /// Useful for validation and UI display
  static Future<Size?> getImageDimensions(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image != null) {
        return Size(image.width.toDouble(), image.height.toDouble());
      }
      return null;
    } catch (e) {
      debugPrint('Error getting image dimensions: $e');
      return null;
    }
  }

  /// Validate if image is suitable for OCR
  /// 
  /// Checks:
  /// - Minimum resolution
  /// - File size
  /// - Image format
  static Future<bool> validateImage(String imagePath) async {
    try {
      final file = File(imagePath);
      
      // Check if file exists
      if (!await file.exists()) {
        return false;
      }

      // Check file size (should be between 50KB and 15MB)
      final fileSize = await file.length();
      if (fileSize < 50 * 1024 || fileSize > 15 * 1024 * 1024) {
        debugPrint('Invalid file size: $fileSize bytes');
        return false;
      }

      // Check image dimensions (minimum 640x480)
      final dimensions = await getImageDimensions(imagePath);
      if (dimensions == null) {
        return false;
      }

      if (dimensions.width < 640 || dimensions.height < 480) {
        debugPrint('Image too small: ${dimensions.width}x${dimensions.height}');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Image validation error: $e');
      return false;
    }
  }

  /// Clean up temporary files
  /// 
  /// Call this to remove old scanned images and free up space
  static Future<void> cleanupTempFiles() async {
    try {
      final directory = await getTemporaryDirectory();
      final files = directory.listSync();

      int deletedCount = 0;
      for (final file in files) {
        if (file is File) {
          final fileName = path.basename(file.path);
          if (fileName.startsWith('enhanced_document_') || 
              fileName.startsWith('scanned_')) {
            // Delete files older than 24 hours
            final stat = await file.stat();
            final age = DateTime.now().difference(stat.modified);
            if (age.inHours > 24) {
              await file.delete();
              deletedCount++;
            }
          }
        }
      }
      
      if (deletedCount > 0) {
        debugPrint('Cleaned up $deletedCount temporary files');
      }
    } catch (e) {
      debugPrint('Cleanup error: $e');
    }
  }

  /// Rotate image by 90 degrees
  /// 
  /// Useful if the captured image is in wrong orientation
  static Future<String?> rotateImage(String imagePath, {int degrees = 90}) async {
    try {
      final imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        return null;
      }

      // Rotate image
      final rotated = img.copyRotate(image, angle: degrees);

      // Save rotated image
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final rotatedPath = path.join(
        directory.path,
        'rotated_$timestamp.jpg',
      );

      final rotatedFile = File(rotatedPath);
      await rotatedFile.writeAsBytes(img.encodeJpg(rotated, quality: 95));

      return rotatedPath;
    } catch (e) {
      debugPrint('Image rotation error: $e');
      return null;
    }
  }
}

/// Custom exception for document scanner errors
class DocumentScannerException implements Exception {
  final String message;
  
  DocumentScannerException(this.message);
  
  @override
  String toString() => 'DocumentScannerException: $message';
}
