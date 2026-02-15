import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthApiService {
  final ApiService _apiService = ApiService();

  // Login
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _apiService.post('/Auth/login', {
        'username': username,
        'password': password,
      }, includeAuth: false);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final token = data['token'];
        final loggedInUsername = data['username'] ?? username;

        await _apiService.saveToken(token);

        // Save username to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_username', loggedInUsername);

        return data;
      } else {
        throw Exception(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  // Get current username
  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_username');
  }

  // Logout
  Future<void> logout() async {
    await _apiService.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_username');
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _apiService.getToken();
    return token != null && token.isNotEmpty;
  }
}
