class VerificationLog {
  final String id;
  final String licenseId;
  final String
  result; // 'active', 'fake', 'expired' (mapped from verificationStatus)
  final DateTime timestamp;
  final bool isReal;
  final bool? isActive;
  final int? checkedBy;
  final String? checkedByUsername;

  VerificationLog({
    required this.id,
    required this.licenseId,
    required this.result,
    required this.timestamp,
    required this.isReal,
    this.isActive,
    this.checkedBy,
    this.checkedByUsername,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'licenseId': licenseId,
      'result': result,
      'timestamp': timestamp.toIso8601String(),
      'isReal': isReal,
      'isActive': isActive,
      'checkedBy': checkedBy,
      'checkedByUsername': checkedByUsername,
    };
  }

  factory VerificationLog.fromJson(Map<String, dynamic> json) {
    // Parse the datetime (already in local time from backend)
    final dateTime = DateTime.parse(json['checkedDate'] ?? json['timestamp']);

    // Get verification status from backend
    final status = (json['verificationStatus'] ?? json['result'] ?? '')
        .toLowerCase();

    // Determine isReal and isActive based on verificationStatus
    final isReal = status == 'active' || status == 'expired';
    final isActive = status == 'active';

    return VerificationLog(
      id: json['logId']?.toString() ?? json['id'] ?? '',
      licenseId: json['licenseId'],
      result: status,
      timestamp: dateTime,
      isReal: isReal,
      isActive: isActive,
      checkedBy: json['checkedBy'],
      checkedByUsername: json['checkedByUsername'],
    );
  }
}
