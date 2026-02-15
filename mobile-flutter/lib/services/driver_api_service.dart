import '../models/driver.dart';
import 'api_service.dart';

class DriverApiService {
  final ApiService _apiService = ApiService();

  // Register a new driver
  Future<int> registerDriver({
    required String licenseId,
    required String fullName,
    required String dateOfBirth,
    required String licenseType,
    required String expiryDate,
    required String qrRawData,
    required String ocrRawText,
    String? region,
  }) async {
    try {
      final response = await _apiService.post('/Driver/register', {
        'licenseId': licenseId,
        'fullName': fullName,
        'dateOfBirth': dateOfBirth,
        'licenseType': licenseType,
        'expiryDate': expiryDate,
        'qrRawData': qrRawData,
        'ocrRawText': ocrRawText,
        'region': region,
      });

      if (response['success'] == true && response['data'] != null) {
        return response['data']['driverId'];
      } else {
        throw Exception(response['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // Get driver by license ID
  Future<Driver?> getDriverByLicenseId(String licenseId) async {
    try {
      final response = await _apiService.get('/Driver/$licenseId');

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        return Driver(
          id: data['driverId'].toString(),
          licenseId: data['licenseId'],
          fullName: data['fullName'],
          dateOfBirth: data['dateOfBirth'],
          address: '', // Not in API response
          licenseType: data['licenseType'],
          issueDate: '', // Not in API response
          expiryDate: data['expiryDate'],
          qrData: data['qrRawData'],
          status: data['status'].toLowerCase(),
          registeredAt: DateTime.parse(data['createdDate']),
        );
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Get all drivers
  Future<List<Driver>> getAllDrivers() async {
    try {
      final response = await _apiService.get('/Driver');

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'];
        return data
            .map(
              (item) => Driver(
                id: item['driverId'].toString(),
                licenseId: item['licenseId'],
                fullName: item['fullName'],
                dateOfBirth: item['dateOfBirth'],
                address: '',
                licenseType: item['licenseType'],
                issueDate: '',
                expiryDate: item['expiryDate'],
                qrData: item['qrRawData'],
                status: item['status'].toLowerCase(),
                registeredAt: DateTime.parse(item['createdDate']),
              ),
            )
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Update driver status
  Future<bool> updateDriverStatus(String licenseId, String status) async {
    try {
      final response = await _apiService.put('/Driver/status', {
        'licenseId': licenseId,
        'status': status,
      });

      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }
}
