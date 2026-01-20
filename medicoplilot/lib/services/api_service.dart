import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';
import 'token_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  final TokenService _tokenService = TokenService();

  // GET request
  Future<dynamic> get(String endpoint, {bool requiresAuth = true}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _buildHeaders(requiresAuth: requiresAuth);

      final response = await http
          .get(url, headers: headers)
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // POST request
  Future<dynamic> post(
    String endpoint,
    dynamic body, {
    bool requiresAuth = false,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _buildHeaders(requiresAuth: requiresAuth);

      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // PUT request
  Future<dynamic> put(
    String endpoint,
    dynamic body, {
    bool requiresAuth = true,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _buildHeaders(requiresAuth: requiresAuth);

      final response = await http
          .put(
            url,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE request
  Future<dynamic> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _buildHeaders(requiresAuth: requiresAuth);

      final response = await http
          .delete(url, headers: headers)
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Build headers with optional auth token
  Future<Map<String, String>> _buildHeaders({
    bool requiresAuth = false,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _tokenService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        throw ApiException('No authentication token found');
      }
    }

    return headers;
  }

  // Handle HTTP response
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }
      return jsonDecode(response.body);
    } else {
      String errorMessage;
      try {
        final errorData = jsonDecode(response.body);
        errorMessage = errorData['detail'] ?? errorData['message'] ?? 'Request failed';
      } catch (e) {
        errorMessage = 'Request failed with status ${response.statusCode}';
      }

      throw ApiException(
        errorMessage,
        statusCode: response.statusCode,
      );
    }
  }

  // Handle errors
  ApiException _handleError(dynamic error) {
    if (error is ApiException) {
      return error;
    } else if (error.toString().contains('TimeoutException')) {
      return ApiException('Request timeout. Please check your connection.');
    } else if (error.toString().contains('SocketException')) {
      return ApiException('No internet connection. Please check your network.');
    } else {
      return ApiException('An unexpected error occurred: ${error.toString()}');
    }
  }
}
