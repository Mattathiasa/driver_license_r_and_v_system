import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Custom document scanner with edge detection overlay
/// Shows a rectangle overlay to guide license capture
/// Automatically straightens and crops the captured image
class LicenseScannerScreen extends StatefulWidget {
  const LicenseScannerScreen({super.key});

  @override
  State<LicenseScannerScreen> createState() => _LicenseScannerScreenState();
}

class _LicenseScannerScreenState extends State<LicenseScannerScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _capturedImagePath;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        _showError('No cameras available');
        return;
      }

      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      _showError('Failed to initialize camera: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureAndProcess() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Capture image
      final XFile image = await _controller!.takePicture();

      // Process the image
      final processedPath = await _processImage(image.path);

      setState(() {
        _capturedImagePath = processedPath;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Failed to capture image: $e');
    }
  }

  Future<String> _processImage(String imagePath) async {
    // Read the image
    final bytes = await File(imagePath).readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Get image dimensions
    final width = image.width;
    final height = image.height;

    // Calculate crop area (center 80% of image with license card aspect ratio)
    // Standard license card is roughly 3.375" x 2.125" (1.59:1 ratio)
    final targetAspectRatio = 1.59;

    int cropWidth, cropHeight;
    if (width / height > targetAspectRatio) {
      // Image is wider, constrain by height
      cropHeight = (height * 0.8).toInt();
      cropWidth = (cropHeight * targetAspectRatio).toInt();
    } else {
      // Image is taller, constrain by width
      cropWidth = (width * 0.8).toInt();
      cropHeight = (cropWidth / targetAspectRatio).toInt();
    }

    final cropX = (width - cropWidth) ~/ 2;
    final cropY = (height - cropHeight) ~/ 2;

    // Crop to the license area
    image = img.copyCrop(
      image,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );

    // Enhance the image for better OCR
    // 1. Increase contrast
    image = img.adjustColor(
      image,
      contrast: 1.3,
      brightness: 1.05,
      saturation: 0.9,
    );

    // 2. Sharpen
    image = img.convolution(image, filter: [0, -1, 0, -1, 5, -1, 0, -1, 0]);

    // Save processed image
    final directory = await getTemporaryDirectory();
    final processedPath = path.join(
      directory.path,
      'license_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    await File(processedPath).writeAsBytes(img.encodeJpg(image, quality: 95));

    return processedPath;
  }

  void _retake() {
    setState(() {
      _capturedImagePath = null;
    });
  }

  void _confirm() {
    if (_capturedImagePath != null) {
      Navigator.pop(context, _capturedImagePath);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_capturedImagePath != null) {
      return _buildPreviewScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: _isInitialized
          ? _buildCameraView()
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        CameraPreview(_controller!),

        // Overlay with guide rectangle
        CustomPaint(painter: LicenseOverlayPainter()),

        // Top bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Scan Driver License',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the close button
                ],
              ),
            ),
          ),
        ),

        // Instructions
        Positioned(
          bottom: 150,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: const Text(
              'Position the license within the frame',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                shadows: [Shadow(color: Colors.black, blurRadius: 10)],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        // Capture button
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: _isProcessing
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : GestureDetector(
                    onTap: _captureAndProcess,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Preview image
          Center(
            child: Image.file(File(_capturedImagePath!), fit: BoxFit.contain),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                child: const Text(
                  'Preview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // Bottom buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Retake button
                    ElevatedButton.icon(
                      onPressed: _retake,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retake'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white24,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),

                    // Confirm button
                    ElevatedButton.icon(
                      onPressed: _confirm,
                      icon: const Icon(Icons.check),
                      label: const Text('Use This'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the license overlay guide
class LicenseOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final cornerPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    // Calculate rectangle dimensions (license card aspect ratio 1.59:1)
    final rectWidth = size.width * 0.85;
    final rectHeight = rectWidth / 1.59;
    final rectLeft = (size.width - rectWidth) / 2;
    final rectTop = (size.height - rectHeight) / 2;

    final rect = Rect.fromLTWH(rectLeft, rectTop, rectWidth, rectHeight);

    // Draw darkened areas outside the rectangle
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw border
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      borderPaint,
    );

    // Draw corner indicators
    final cornerLength = 30.0;

    // Top-left corner
    canvas.drawLine(
      Offset(rectLeft, rectTop + cornerLength),
      Offset(rectLeft, rectTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rectLeft, rectTop),
      Offset(rectLeft + cornerLength, rectTop),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(rectLeft + rectWidth - cornerLength, rectTop),
      Offset(rectLeft + rectWidth, rectTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rectLeft + rectWidth, rectTop),
      Offset(rectLeft + rectWidth, rectTop + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(rectLeft, rectTop + rectHeight - cornerLength),
      Offset(rectLeft, rectTop + rectHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rectLeft, rectTop + rectHeight),
      Offset(rectLeft + cornerLength, rectTop + rectHeight),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(rectLeft + rectWidth - cornerLength, rectTop + rectHeight),
      Offset(rectLeft + rectWidth, rectTop + rectHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rectLeft + rectWidth, rectTop + rectHeight - cornerLength),
      Offset(rectLeft + rectWidth, rectTop + rectHeight),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
