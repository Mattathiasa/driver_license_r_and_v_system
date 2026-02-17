import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Debug screen to test QR code scanning and view raw data
class QRDebugScreen extends StatefulWidget {
  const QRDebugScreen({super.key});

  @override
  State<QRDebugScreen> createState() => _QRDebugScreenState();
}

class _QRDebugScreenState extends State<QRDebugScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.normal,
  );

  String? rawValue;
  String? displayValue;
  String? format;
  String? type;
  List<int>? rawBytes;
  String? decodedFromBytes;
  int detectionCount = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Debug Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: () => _controller.switchCamera(),
          ),
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Scanner view
          Expanded(
            flex: 2,
            child: MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final barcode = barcodes.first;
                  setState(() {
                    detectionCount++;
                    rawValue = barcode.rawValue;
                    displayValue = barcode.displayValue;
                    format = barcode.format.name;
                    type = barcode.type.name;
                    rawBytes = barcode.rawBytes;

                    // Try to decode from bytes if available
                    if (rawBytes != null) {
                      try {
                        decodedFromBytes = String.fromCharCodes(rawBytes!);
                      } catch (e) {
                        decodedFromBytes = 'Error decoding: $e';
                      }
                    }
                  });
                }
              },
            ),
          ),

          // Debug info panel
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildInfoRow('Detections', detectionCount.toString()),
                    _buildInfoRow('Format', format ?? 'None'),
                    _buildInfoRow('Type', type ?? 'None'),

                    const Divider(color: Colors.white30, height: 32),

                    _buildCopyableSection('Raw Value', rawValue ?? 'No data'),

                    const SizedBox(height: 16),

                    _buildCopyableSection(
                      'Display Value',
                      displayValue ?? 'No data',
                    ),

                    const SizedBox(height: 16),

                    _buildCopyableSection(
                      'Raw Bytes',
                      rawBytes?.toString() ?? 'No data',
                    ),

                    const SizedBox(height: 16),

                    _buildCopyableSection(
                      'Decoded from Bytes',
                      decodedFromBytes ?? 'No data',
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableSection(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.white70, size: 20),
              onPressed: () => _copyToClipboard(value),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white30),
          ),
          child: SelectableText(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
