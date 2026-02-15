import '../models/verification_log.dart';
import 'api_service.dart';

class VerificationResult {
  final bool isReal;
  final bool isActive;
  final String message;
  final String? driverName;
  final String? expiryDate;

  VerificationResult({
    required this.isReal,
    required this.isActive,
    required this.message,
    this.driverName,
    this.expiryDate,
  });
}

class VerificationApiService {
  final ApiService _apiService = ApiService();

  // Verify license
  Future<VerificationResult> verifyLicense({
    required String licenseId,
    required String qrRawData,
    String? notes,
  }) async {
    try {
      final response = await _apiService.post('/Verification/verify', {
        'licenseId': licenseId,
        'qrRawData': qrRawData,
        'notes': notes,
      });

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        return VerificationResult(
          isReal: data['isReal'] ?? false,
          isActive: data['isActive'] ?? false,
          message: data['message'] ?? '',
          driverName: data['driverName'],
          expiryDate: data['expiryDate'],
        );
      } else {
        throw Exception(response['message'] ?? 'Verification failed');
      }
    } catch (e) {
      throw Exception('Verification failed: ${e.toString()}');
    }
  }

  // Get license status
  Future<Map<String, dynamic>> getLicenseStatus(String licenseId) async {
    try {
      final response = await _apiService.get('/Verification/status/$licenseId');

      if (response['success'] == true && response['data'] != null) {
        return response['data'];
      } else {
        throw Exception(response['message'] ?? 'Status check failed');
      }
    } catch (e) {
      throw Exception('Status check failed: ${e.toString()}');
    }
  }

  // Get verification logs
  Future<List<VerificationLog>> getVerificationLogs() async {
    try {
      final response = await _apiService.get('/Verification/logs');

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'];
        return data.map((item) => VerificationLog.fromJson(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Get dashboard stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _apiService.get('/Verification/dashboard');

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;

        // Normalize keys to camelCase in case backend returns PascalCase
        return {
          'totalDrivers': data['totalDrivers'] ?? data['TotalDrivers'] ?? 0,
          'activeDrivers': data['activeDrivers'] ?? data['ActiveDrivers'] ?? 0,
          'expiredDrivers':
              data['expiredDrivers'] ?? data['ExpiredDrivers'] ?? 0,
          'totalVerifications':
              data['totalVerifications'] ?? data['TotalVerifications'] ?? 0,
          'realVerifications':
              data['realVerifications'] ?? data['RealVerifications'] ?? 0,
          'fakeVerifications':
              data['fakeVerifications'] ?? data['FakeVerifications'] ?? 0,
        };
      }
      return _emptyStats();
    } catch (e) {
      return _emptyStats();
    }
  }

  Map<String, dynamic> _emptyStats() {
    return {
      'totalDrivers': 0,
      'activeDrivers': 0,
      'expiredDrivers': 0,
      'totalVerifications': 0,
      'realVerifications': 0,
      'fakeVerifications': 0,
    };
  }

  // Export logs to CSV
  Future<String?> exportLogs() async {
    try {
      final response = await _apiService.getRaw('/Verification/export');
      if (response.statusCode == 200) {
        return response.body;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
