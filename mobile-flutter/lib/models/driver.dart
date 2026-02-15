class Driver {
  final String id;
  final String licenseId;
  final String fullName;
  final String dateOfBirth;
  final String address;
  final String licenseType;
  final String issueDate;
  final String expiryDate;
  final String? imagePath;
  final String? qrData;
  final String status; // 'active', 'expired'
  final DateTime registeredAt;

  Driver({
    required this.id,
    required this.licenseId,
    required this.fullName,
    required this.dateOfBirth,
    required this.address,
    required this.licenseType,
    required this.issueDate,
    required this.expiryDate,
    this.imagePath,
    this.qrData,
    required this.status,
    required this.registeredAt,
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
      'dateOfBirth': dateOfBirth,
      'address': address,
      'licenseType': licenseType,
      'issueDate': issueDate,
      'expiryDate': expiryDate,
      'imagePath': imagePath,
      'qrData': qrData,
      'status': status,
      'registeredAt': registeredAt.toIso8601String(),
    };
  }

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      licenseId: json['licenseId'],
      fullName: json['fullName'],
      dateOfBirth: json['dateOfBirth'],
      address: json['address'],
      licenseType: json['licenseType'],
      issueDate: json['issueDate'],
      expiryDate: json['expiryDate'],
      imagePath: json['imagePath'],
      qrData: json['qrData'],
      status: json['status'],
      registeredAt: DateTime.parse(json['registeredAt']),
    );
  }

  Driver copyWith({
    String? id,
    String? licenseId,
    String? fullName,
    String? dateOfBirth,
    String? address,
    String? licenseType,
    String? issueDate,
    String? expiryDate,
    String? imagePath,
    String? qrData,
    String? status,
    DateTime? registeredAt,
  }) {
    return Driver(
      id: id ?? this.id,
      licenseId: licenseId ?? this.licenseId,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      licenseType: licenseType ?? this.licenseType,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      imagePath: imagePath ?? this.imagePath,
      qrData: qrData ?? this.qrData,
      status: status ?? this.status,
      registeredAt: registeredAt ?? this.registeredAt,
    );
  }
}
