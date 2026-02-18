import '../models/driver.dart';
import 'api_service.dart';

class DriverApiService {
  final ApiService _apiService = ApiService();

  // Register a new driver
  Future<int> registerDriver({
    required String licenseId,
    required String fullName,
    required String licenseType,
    required String expiryDate,
    required String qrRawData,
    required String ocrRawText,
  }) async {
    try {
      final response = await _apiService.post('/Driver/register', {
        'licenseId': licenseId,
        'fullName': fullName,
        'licenseType': licenseType,
        'expiryDate': expiryDate,
        'qrRawData': qrRawData,
        'ocrRawText': ocrRawText,
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
        return Driver.fromJson(response['data']);
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
      print('DEBUG: Calling /Driver endpoint...');
      final response = await _apiService.get('/Driver');

      print('DEBUG: Response success: ${response['success']}');
      print('DEBUG: Response data type: ${response['data']?.runtimeType}');

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'];
        print('DEBUG: Number of drivers in response: ${data.length}');

        final drivers = data.map((item) => Driver.fromJson(item)).toList();

        print('DEBUG: Successfully parsed ${drivers.length} drivers');
        return drivers;
      } else {
        print('DEBUG: Response not successful or data is null');
        return [];
      }
    } catch (e) {
      print('DEBUG: Error in getAllDrivers: $e');
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

  // Get driver statistics directly from backend
  Future<Map<String, dynamic>> getDriverStatistics() async {
    try {
      print('DEBUG: Calling /Driver/statistics endpoint...');
      final response = await _apiService.get('/Driver/statistics');

      print('DEBUG: Statistics response: $response');

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        print('DEBUG: Statistics data: $data');

        return {
          'totalDrivers': data['totalDrivers'] ?? 0,
          'activeDrivers': data['activeDrivers'] ?? 0,
          'expiredDrivers': data['expiredDrivers'] ?? 0,
        };
      } else {
        print('DEBUG: Statistics response not successful');
        return {'totalDrivers': 0, 'activeDrivers': 0, 'expiredDrivers': 0};
      }
    } catch (e) {
      print('DEBUG: Error getting driver statistics: $e');
      return {'totalDrivers': 0, 'activeDrivers': 0, 'expiredDrivers': 0};
    }
  }
}
