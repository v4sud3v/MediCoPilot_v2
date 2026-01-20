import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class TokenService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _userKey = 'user_data';
  static const _doctorKey = 'doctor_data';

  // Save authentication token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Get authentication token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Delete authentication token
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // Check if token exists
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Save user data
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _storage.write(key: _userKey, value: jsonEncode(userData));
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    final data = await _storage.read(key: _userKey);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  // Save doctor data
  Future<void> saveDoctorData(Map<String, dynamic> doctorData) async {
    await _storage.write(key: _doctorKey, value: jsonEncode(doctorData));
  }

  // Get doctor data
  Future<Map<String, dynamic>?> getDoctorData() async {
    final data = await _storage.read(key: _doctorKey);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  // Clear all stored data (logout)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
