class VerificationLog {
  final String id;
  final String licenseId;
  final String
  result; // 'real', 'fake', 'expired' (mapped from verificationStatus)
  final DateTime timestamp;
  final String? driverName;
  final bool isReal;
  final bool? isActive;
  final int? checkedBy;
  final String? notes;

  VerificationLog({
    required this.id,
    required this.licenseId,
    required this.result,
    required this.timestamp,
    this.driverName,
    required this.isReal,
    this.isActive,
    this.checkedBy,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'licenseId': licenseId,
      'result': result,
      'timestamp': timestamp.toIso8601String(),
      'driverName': driverName,
      'isReal': isReal,
      'isActive': isActive,
      'checkedBy': checkedBy,
      'notes': notes,
    };
  }

  factory VerificationLog.fromJson(Map<String, dynamic> json) {
    return VerificationLog(
      id: json['logId']?.toString() ?? json['id'] ?? '',
      licenseId: json['licenseId'],
      result: json['verificationStatus'] ?? json['result'] ?? '',
      timestamp: DateTime.parse(json['checkedDate'] ?? json['timestamp']),
      driverName: json['driverName'],
      isReal: json['isReal'] ?? (json['result'] == 'real'),
      isActive: json['isActive'],
      checkedBy: json['checkedBy'],
      notes: json['notes'],
    );
  }
}
