class Driver {
  final String id;
  final String licenseId;
  final String fullName;
  final String licenseType;
  final String expiryDate;
  final String? qrData;
  final String? ocrRawText;
  final String status;
  final DateTime registeredAt;
  final String registeredBy;

  Driver({
    required this.id,
    required this.licenseId,
    required this.fullName,
    required this.licenseType,
    required this.expiryDate,
    this.qrData,
    this.ocrRawText,
    required this.status,
    required this.registeredAt,
    required this.registeredBy,
  });

  // Calculate status based on expiry date
  static String calculateStatus(String expiryDate) {
    try {
      final parts = expiryDate.split('/');
      if (parts.length != 3) return 'active';

      final expiry = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );

      return expiry.isBefore(DateTime.now()) ? 'expired' : 'active';
    } catch (e) {
      return 'active';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'licenseId': licenseId,
      'fullName': fullName,
      'licenseType': licenseType,
      'expiryDate': expiryDate,
      'qrData': qrData,
      'ocrRawText': ocrRawText,
      'status': status,
      'registeredAt': registeredAt.toIso8601String(),
      'registeredBy': registeredBy,
    };
  }

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['driverId']?.toString() ?? json['id']?.toString() ?? '',
      licenseId: json['licenseId'] ?? '',
      fullName: json['fullName'] ?? '',
      licenseType: json['licenseType'] ?? '',
      expiryDate: json['expiryDate'] ?? '',
      qrData: json['qrRawData'],
      ocrRawText: json['ocrRawText'],
      status: json['status'] ?? 'active',
      registeredAt: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'])
          : DateTime.now(),
      registeredBy: json['registeredByUsername'] ?? 'Unknown',
    );
  }

  Driver copyWith({
    String? id,
    String? licenseId,
    String? fullName,
    String? licenseType,
    String? expiryDate,
    String? qrData,
    String? ocrRawText,
    String? status,
    DateTime? registeredAt,
    String? registeredBy,
  }) {
    return Driver(
      id: id ?? this.id,
      licenseId: licenseId ?? this.licenseId,
      fullName: fullName ?? this.fullName,
      licenseType: licenseType ?? this.licenseType,
      expiryDate: expiryDate ?? this.expiryDate,
      qrData: qrData ?? this.qrData,
      ocrRawText: ocrRawText ?? this.ocrRawText,
      status: status ?? this.status,
      registeredAt: registeredAt ?? this.registeredAt,
      registeredBy: registeredBy ?? this.registeredBy,
    );
  }
}
