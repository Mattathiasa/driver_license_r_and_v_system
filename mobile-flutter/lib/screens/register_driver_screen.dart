import 'dart:io';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/driver_api_service.dart';
import '../services/ocr_service.dart';
import '../services/notification_service.dart';

class RegisterDriverScreen extends StatefulWidget {
  final Map<String, String>? prefilledData;
  final String? imagePath;

  const RegisterDriverScreen({super.key, this.prefilledData, this.imagePath});

  @override
  State<RegisterDriverScreen> createState() => _RegisterDriverScreenState();
}

class _RegisterDriverScreenState extends State<RegisterDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _driverApiService = DriverApiService();

  late TextEditingController _licenseIdController;
  late TextEditingController _fullNameController;
  late TextEditingController _licenseTypeController;
  late TextEditingController _expiryDateController;
  late TextEditingController _qrRawDataController;
  late TextEditingController _ocrRawTextController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _licenseIdController = TextEditingController(
      text: widget.prefilledData?['licenseId'] ?? '',
    );
    _fullNameController = TextEditingController(
      text: widget.prefilledData?['fullName'] ?? '',
    );
    _licenseTypeController = TextEditingController(
      text: widget.prefilledData?['licenseType'] ?? '',
    );
    _expiryDateController = TextEditingController(
      text: widget.prefilledData?['expiryDate'] ?? '',
    );
    _qrRawDataController = TextEditingController(
      text: widget.prefilledData?['qrRawData'] ?? '',
    );
    _ocrRawTextController = TextEditingController(
      text: widget.prefilledData?['ocrRawText'] ?? '',
    );
  }

  @override
  void dispose() {
    _licenseIdController.dispose();
    _fullNameController.dispose();
    _licenseTypeController.dispose();
    _expiryDateController.dispose();
    _qrRawDataController.dispose();
    _ocrRawTextController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Normalize license ID (auto-prepend 'A' if only 5 digits)
      final normalizedLicenseId = OCRService.normalizeLicenseId(
        _licenseIdController.text,
      );
      _licenseIdController.text = normalizedLicenseId;

      // Use raw data from controllers if available, otherwise generate
      final qrData = _qrRawDataController.text.isNotEmpty
          ? _qrRawDataController.text
          : OCRService.generateQRData({
              'licenseId': normalizedLicenseId,
              'fullName': _fullNameController.text,
              'licenseType': _licenseTypeController.text,
              'expiryDate': _expiryDateController.text,
              'address': '',
            });

      final ocrText = _ocrRawTextController.text.isNotEmpty
          ? _ocrRawTextController.text
          : 'License ID: $normalizedLicenseId\n'
                'Name: ${_fullNameController.text}\n'
                'Grade: ${_licenseTypeController.text}\n'
                'Expiry: ${_expiryDateController.text}';

      await _driverApiService.registerDriver(
        licenseId: normalizedLicenseId,
        fullName: _fullNameController.text,
        licenseType: _licenseTypeController.text,
        expiryDate: _expiryDateController.text,
        qrRawData: qrData,
        ocrRawText: ocrText,
      );

      if (mounted) {
        // Show success notification
        await NotificationService().showSuccessNotification(
          licenseId: normalizedLicenseId,
          fullName: _fullNameController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Driver ${_fullNameController.text} registered successfully!',
                    style: GoogleFonts.outfit(),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.teal.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        final isAlreadyRegistered = errorMessage.toLowerCase().contains(
          'already registered',
        );

        // Extract status from error message if present
        String status = 'Active';
        if (errorMessage.contains('Status: ACTIVE')) {
          status = 'Active';
        } else if (errorMessage.contains('Status: EXPIRED')) {
          status = 'Expired';
        }

        // Show duplicate license notification
        if (isAlreadyRegistered) {
          await NotificationService().showDuplicateLicenseNotification(
            licenseId: _licenseIdController.text,
            fullName: _fullNameController.text,
            status: status,
          );
        }

        // Show dialog for already registered licenses
        if (isAlreadyRegistered) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade700,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Already Registered',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'License ID: ${_licenseIdController.text}',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: status == 'Active'
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: status == 'Active'
                              ? Colors.green.shade200
                              : Colors.orange.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            status == 'Active'
                                ? Icons.check_circle_outline
                                : Icons.event_busy,
                            color: status == 'Active'
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Status',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  status.toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: status == 'Active'
                                        ? Colors.green.shade700
                                        : Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'This license is already in the system and cannot be registered again.',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'OK',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              );
            },
          );
        } else {
          // Show snackbar for other errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(errorMessage, style: GoogleFonts.outfit()),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
              Colors.blue.shade700,
              Colors.blue.shade600,
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
                              'Register Driver',
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Issue new digital license',
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

              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.imagePath != null)
                          FadeInUp(
                            delay: const Duration(milliseconds: 100),
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
                                  File(widget.imagePath!),
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        if (widget.imagePath != null)
                          const SizedBox(height: 32),

                        FadeInUp(
                          delay: const Duration(milliseconds: 200),
                          child: _buildTextField(
                            controller: _licenseIdController,
                            label: 'License ID',
                            icon: Icons.badge_rounded,
                            hint: 'e.g., A12997, 12997, AU 321, DL123456',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter license ID';
                              }
                              final trimmed = value.trim();

                              // Accept standalone 5 digits (will auto-prefix with 'A')
                              if (RegExp(r'^\d{5}$').hasMatch(trimmed)) {
                                // Auto-prefix with 'A' for Ethiopian format
                                _licenseIdController.text = 'A$trimmed';
                                return null;
                              }
                              // Accept Ethiopian format: Letter + 5 digits (A12997)
                              if (RegExp(
                                r'^[A-Z]\d{5}$',
                                caseSensitive: false,
                              ).hasMatch(trimmed)) {
                                return null;
                              }
                              // Accept diplomatic formats: AU 321, CD AU 123, CD 456
                              if (RegExp(
                                r'^(CD\s*AU|AU|CD)\s*\d{3}$',
                                caseSensitive: false,
                              ).hasMatch(trimmed)) {
                                return null;
                              }
                              // Accept standard alphanumeric IDs (4-15 characters)
                              if (RegExp(
                                r'^[A-Z0-9]{4,15}$',
                                caseSensitive: false,
                              ).hasMatch(trimmed)) {
                                return null;
                              }
                              return 'Invalid format. Use A12997, 12997, AU 321, or DL123456';
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        FadeInUp(
                          delay: const Duration(milliseconds: 300),
                          child: _buildTextField(
                            controller: _fullNameController,
                            label: 'Full Name',
                            icon: Icons.person_rounded,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter full name';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        FadeInUp(
                          delay: const Duration(milliseconds: 500),
                          child: _buildTextField(
                            controller: _licenseTypeController,
                            label: 'Grade',
                            icon: Icons.stars_rounded,
                            hint: 'e.g., A, B, C, D, E',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter grade';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        FadeInUp(
                          delay: const Duration(milliseconds: 600),
                          child: _buildDateField(
                            controller: _expiryDateController,
                            label: 'Expiry Date',
                            icon: Icons.event_busy_rounded,
                            hint: 'YYYY-MM-DD',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter expiry date';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        FadeInUp(
                          delay: const Duration(milliseconds: 650),
                          child: _buildTextField(
                            controller: _qrRawDataController,
                            label: 'QR Raw Data',
                            icon: Icons.qr_code_rounded,
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(height: 16),

                        FadeInUp(
                          delay: const Duration(milliseconds: 700),
                          child: _buildTextField(
                            controller: _ocrRawTextController,
                            label: 'OCR Raw Text',
                            icon: Icons.text_snippet_rounded,
                            maxLines: 3,
                          ),
                        ),
                        const SizedBox(height: 32),

                        FadeInUp(
                          delay: const Duration(milliseconds: 750),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 5,
                              shadowColor: Colors.blue.withValues(alpha: 0.3),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.person_add_alt_1_rounded,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Register Driver',
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
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
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.outfit(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(color: Colors.blueGrey.shade600),
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400),
          prefixIcon: Icon(icon, color: Colors.blue.shade700),
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
        validator: validator,
        enabled: !_isLoading,
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Container(
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
      child: TextFormField(
        controller: controller,
        readOnly: true,
        style: GoogleFonts.outfit(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(color: Colors.blueGrey.shade600),
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400),
          prefixIcon: Icon(icon, color: Colors.blue.shade700),
          suffixIcon: Icon(Icons.calendar_today, color: Colors.blue.shade700),
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
        validator: validator,
        enabled: !_isLoading,
        onTap: () async {
          if (_isLoading) return;

          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: controller.text.isNotEmpty
                ? DateTime.tryParse(controller.text) ?? DateTime.now()
                : DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime(2050),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: Colors.blue.shade700,
                    onPrimary: Colors.white,
                    onSurface: Colors.blueGrey.shade900,
                  ),
                ),
                child: child!,
              );
            },
          );

          if (picked != null) {
            controller.text =
                '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          }
        },
      ),
    );
  }
}
