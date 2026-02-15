import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/driver.dart';
import '../models/verification_log.dart';

class StorageService {
  static const String _driversKey = 'drivers';
  static const String _verificationLogsKey = 'verification_logs';
  static const String _currentUserKey = 'current_user';

  // Save all drivers
  Future<void> saveDrivers(List<Driver> drivers) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = drivers.map((d) => d.toJson()).toList();
    await prefs.setString(_driversKey, jsonEncode(jsonList));
  }

  // Get all drivers
  Future<List<Driver>> getDrivers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_driversKey);
    
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Driver.fromJson(json)).toList();
  }

  // Add a driver
  Future<void> addDriver(Driver driver) async {
    final drivers = await getDrivers();
    drivers.add(driver);
    await saveDrivers(drivers);
  }

  // Check if license ID exists
  Future<bool> licenseExists(String licenseId) async {
    final drivers = await getDrivers();
    return drivers.any((d) => d.licenseId.toLowerCase() == licenseId.toLowerCase());
  }

  // Get driver by license ID
  Future<Driver?> getDriverByLicenseId(String licenseId) async {
    final drivers = await getDrivers();
    try {
      return drivers.firstWhere(
        (d) => d.licenseId.toLowerCase() == licenseId.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Save verification logs
  Future<void> saveVerificationLogs(List<VerificationLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = logs.map((l) => l.toJson()).toList();
    await prefs.setString(_verificationLogsKey, jsonEncode(jsonList));
  }

  // Get verification logs
  Future<List<VerificationLog>> getVerificationLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_verificationLogsKey);
    
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => VerificationLog.fromJson(json)).toList();
  }

  // Add verification log
  Future<void> addVerificationLog(VerificationLog log) async {
    final logs = await getVerificationLogs();
    logs.add(log);
    await saveVerificationLogs(logs);
  }

  // Authentication
  Future<void> setCurrentUser(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, username);
  }

  Future<String?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  // Get statistics
  Future<Map<String, int>> getStatistics() async {
    final drivers = await getDrivers();
    
    int total = drivers.length;
    int active = drivers.where((d) => d.status == 'active').length;
    int expired = drivers.where((d) => d.status == 'expired').length;
    
    return {
      'total': total,
      'active': active,
      'expired': expired,
    };
  }
}
