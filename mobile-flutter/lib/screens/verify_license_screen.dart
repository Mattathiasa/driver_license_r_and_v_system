import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../models/driver.dart';
import '../services/verification_api_service.dart';
import '../services/driver_api_service.dart';
import '../services/ocr_service.dart';
import '../services/notification_service.dart';

class VerifyLicenseScreen extends StatefulWidget {
  const VerifyLicenseScreen({super.key});

  @override
  State<VerifyLicenseScreen> createState() => _VerifyLicenseScreenState();
}

class _VerifyLicenseScreenState extends State<VerifyLicenseScreen> {
  final _verificationApiService = VerificationApiService();
  final _driverApiService = DriverApiService();
  final _licenseIdController = TextEditingController();
  final _notesController = TextEditingController();

  bool _showScanner = false;
  bool _isVerifying = false;
  Driver? _verifiedDriver;
  String? _verificationResult;
  String? _verificationMessage;
  QRViewController? _qrController;
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void dispose() {
    _licenseIdController.dispose();
    _notesController.dispose();
    _qrController?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    _qrController = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null && !_isVerifying) {
        controller.pauseCamera();
        _verifyFromQR(scanData.code!);
      }
    });
  }

  Future<void> _verifyFromQR(String qrData) async {
    setState(() {
      _showScanner = false;
      _isVerifying = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Extract data from QR using real OCRService
      final extractedData = OCRService.parseQRData(qrData);
      final licenseId = extractedData['licenseId'] ?? '';

      _licenseIdController.text = licenseId;
      await _performVerification(licenseId, qrRawData: qrData);
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _verificationResult = 'fake';
      });
      _logVerification('UNKNOWN', 'fake', null);
    }
  }

  Future<void> _verifyManual() async {
    if (_licenseIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a license ID',
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Normalize license ID (auto-prepend 'A' if only 5 digits)
    final normalizedId = OCRService.normalizeLicenseId(
      _licenseIdController.text,
    );
    _licenseIdController.text = normalizedId;

    setState(() => _isVerifying = true);
    await _performVerification(normalizedId, notes: _notesController.text);
  }

  Future<void> _performVerification(
    String licenseId, {
    String? notes,
    String? qrRawData,
  }) async {
    setState(() => _isVerifying = true);

    try {
      // Use the provided raw QR data or fallback to the controller text
      final finalQrData = qrRawData ?? _licenseIdController.text;

      final result = await _verificationApiService.verifyLicense(
        licenseId: licenseId,
        qrRawData: finalQrData,
        notes: notes,
      );

      // Fetch full driver details if successfully verified
      Driver? driver;
      if (result.isReal) {
        driver = await _driverApiService.getDriverByLicenseId(licenseId);
      }

      setState(() {
        _verifiedDriver = driver;
        _verificationResult = result.isReal
            ? (result.isActive ? 'real' : 'expired')
            : 'fake';
        _verificationMessage = result.message;
        _isVerifying = false;
      });

      // Trigger Security Push Notification if fake
      if (!result.isReal) {
        await NotificationService().showNotification(
          title: '🚨 Security Alert',
          body: 'Invalid or missing license detected: $licenseId',
        );
      } else if (!result.isActive) {
        await NotificationService().showNotification(
          title: '⚠️ Expiration Warning',
          body: 'License $licenseId is real but has expired.',
        );
      }
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');

      setState(() {
        _isVerifying = false;
        _verificationResult = 'fake';
        _verificationMessage = errorMsg;
      });

      // Trigger Push Notification for tampering/errors
      await NotificationService().showNotification(
        title: '🔒 System Alert',
        body: 'Verification error or tampering detected: $errorMsg',
      );
    }
  }

  // API handles logging on server side, so we don't need local logging here
  // But we'll keep the method signature for compatibility if needed, though unused
  Future<void> _logVerification(
    String licenseId,
    String result,
    String? driverName,
  ) async {
    // Backend logs this automatically in the verify endpoint
  }

  void _reset() {
    setState(() {
      _licenseIdController.clear();
      _notesController.clear();
      _verifiedDriver = null;
      _verificationResult = null;
      _verificationMessage = null;
      _showScanner = false;
    });
  }

  MaterialColor _getResultColor() {
    switch (_verificationResult) {
      case 'real':
        return Colors.teal;
      case 'expired':
        return Colors.orange;
      case 'fake':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getResultIcon() {
    switch (_verificationResult) {
      case 'real':
        return Icons.verified_rounded;
      case 'expired':
        return Icons.warning_rounded;
      case 'fake':
        return Icons.error_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  String _getResultTitle() {
    switch (_verificationResult) {
      case 'real':
        return 'Valid License';
      case 'expired':
        return 'Expired License';
      case 'fake':
        return 'Invalid License';
      default:
        return 'Unknown';
    }
  }

  String _getResultMessage() {
    if (_verificationMessage != null && _verificationMessage!.isNotEmpty) {
      return _verificationMessage!;
    }
    switch (_verificationResult) {
      case 'real':
        return 'This license is valid and active in the system.';
      case 'expired':
        return 'This license has technical expiration and needs renewal.';
      case 'fake':
        return 'This license ID was not found in our central registry.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _showScanner ? _buildScanner() : _buildContent(),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        QRView(
          key: _qrKey,
          onQRViewCreated: _onQRViewCreated,
          overlay: QrScannerOverlayShape(
            borderColor: Colors.teal,
            borderRadius: 16,
            borderLength: 40,
            borderWidth: 8,
            cutOutSize: MediaQuery.of(context).size.width * 0.8,
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              FadeInDown(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() => _showScanner = false);
                          _qrController?.dispose();
                        },
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scan QR Code',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Align the code within the frame',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.teal.shade700,
            Colors.teal.shade600,
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
                            'Verify License',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Check license authenticity',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_verificationResult != null)
                    FadeInRight(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: _reset,
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                          ),
                          tooltip: 'New Verification',
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_verificationResult == null) _buildForm(),
                    if (_verificationResult != null) _buildResult(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Illustration card
        FadeInUp(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shield_rounded,
                    size: 64,
                    color: Colors.teal.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Quick Verification',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scan the license QR code or enter the ID manually to verify against the central database.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.blueGrey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // QR Button
        FadeInUp(
          delay: const Duration(milliseconds: 100),
          child: ElevatedButton.icon(
            onPressed: _isVerifying
                ? null
                : () => setState(() => _showScanner = true),
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: Text(
              'Scan QR Code',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
          ),
        ),

        const SizedBox(height: 24),
        FadeInUp(
          delay: const Duration(milliseconds: 200),
          child: Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR MANUALLY',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade300,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Manual Input
        FadeInUp(
          delay: const Duration(milliseconds: 300),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _licenseIdController,
              enabled: !_isVerifying,
              style: GoogleFonts.outfit(),
              decoration: InputDecoration(
                labelText: 'License ID',
                labelStyle: GoogleFonts.outfit(color: Colors.blueGrey.shade400),
                prefixIcon: Icon(
                  Icons.badge_rounded,
                  color: Colors.teal.shade600,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Notes Input
        FadeInUp(
          delay: const Duration(milliseconds: 350),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _notesController,
              enabled: !_isVerifying,
              style: GoogleFonts.outfit(),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Verification Notes (Optional)',
                labelStyle: GoogleFonts.outfit(color: Colors.blueGrey.shade400),
                prefixIcon: Icon(
                  Icons.note_add_rounded,
                  color: Colors.teal.shade600,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),
        FadeInUp(
          delay: const Duration(milliseconds: 400),
          child: ElevatedButton(
            onPressed: _isVerifying ? null : _verifyManual,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isVerifying
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Verify Identity',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final color = _getResultColor();
    return FadeInUp(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              children: [
                ZoomIn(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: color.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getResultIcon(),
                      size: 72,
                      color: color.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _getResultTitle(),
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getResultMessage(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: Colors.blueGrey.shade600,
                  ),
                ),

                if (_verifiedDriver != null) ...[
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),
                  _buildDetailRow('License ID', _verifiedDriver!.licenseId),
                  _buildDetailRow('Full Name', _verifiedDriver!.fullName),
                  _buildDetailRow(
                    'Grade (Gerad)',
                    'Class ${_verifiedDriver!.licenseType}',
                  ),
                  _buildDetailRow('Expiry Date', _verifiedDriver!.expiryDate),
                  _buildDetailRow(
                    'Status',
                    _verifiedDriver!.status.toUpperCase(),
                    valueColor: _verifiedDriver!.status == 'active'
                        ? Colors.teal
                        : Colors.orange,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: TextButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'Start New Verification',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blueGrey.shade600,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.blueGrey.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.blueGrey.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
