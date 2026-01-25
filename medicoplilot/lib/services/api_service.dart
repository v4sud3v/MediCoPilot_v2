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
          .post(url, headers: headers, body: jsonEncode(body))
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
          .put(url, headers: headers, body: jsonEncode(body))
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE request
  Future<dynamic> delete(String endpoint, {bool requiresAuth = true}) async {
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
  Future<Map<String, String>> _buildHeaders({bool requiresAuth = false}) async {
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
        errorMessage =
            errorData['detail'] ?? errorData['message'] ?? 'Request failed';
      } catch (e) {
        errorMessage = 'Request failed with status ${response.statusCode}';
      }

      throw ApiException(errorMessage, statusCode: response.statusCode);
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

  // Analyze encounter endpoint
  Future<dynamic> analyzeEncounter({
    required String patientId,
    required String diagnosis,
    required String symptoms,
    required Map<String, dynamic> vitalSigns,
    String? examinationFindings,
  }) async {
    final body = {
      'patient_id': patientId,
      'diagnosis': diagnosis,
      'symptoms': symptoms,
      'vital_signs': vitalSigns,
      if (examinationFindings != null)
        'examination_findings': examinationFindings,
    };

    return post('/analysis/encounter', body, requiresAuth: false);
  }

  // Patient Education endpoints
  Future<dynamic> getPatientEducationForDoctor(
    String doctorId, {
    String? status,
    int limit = 100,
    int offset = 0,
  }) async {
    String endpoint =
        '/patient-education/doctor/$doctorId?limit=$limit&offset=$offset';
    if (status != null) {
      endpoint += '&status=$status';
    }
    return get(endpoint, requiresAuth: false);
  }

  Future<dynamic> getPatientEducationByEncounter(String encounterId) async {
    return get(
      '/patient-education/encounter/$encounterId',
      requiresAuth: false,
    );
  }

  Future<dynamic> getPatientEducationById(String educationId) async {
    return get('/patient-education/$educationId', requiresAuth: false);
  }

  Future<dynamic> updatePatientEducation(
    String educationId, {
    String? title,
    String? description,
    String? content,
    String? status,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (content != null) body['content'] = content;
    if (status != null) body['status'] = status;

    return put('/patient-education/$educationId', body, requiresAuth: false);
  }

  Future<dynamic> sendPatientEducation(String educationId) async {
    return post(
      '/patient-education/$educationId/send',
      {},
      requiresAuth: false,
    );
  }

  // Patient Summary endpoints
  Future<dynamic> getPatientSummariesForDoctor(
    String doctorId, {
    int limit = 100,
    int offset = 0,
  }) async {
    return get(
      '/patient-education/summary/doctor/$doctorId?limit=$limit&offset=$offset',
      requiresAuth: false,
    );
  }

  Future<dynamic> getPatientSummaryByEncounter(String encounterId) async {
    return get(
      '/patient-education/summary/encounter/$encounterId',
      requiresAuth: false,
    );
  }

  Future<dynamic> getPatientSummariesForPatient(
    String patientId, {
    int limit = 50,
  }) async {
    return get(
      '/patient-education/summary/patient/$patientId?limit=$limit',
      requiresAuth: false,
    );
  }
}
