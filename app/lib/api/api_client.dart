import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// Android emulator maps host machine localhost to 10.0.2.2.
// Change this to your machine's LAN IP if testing on a physical device.
const String kBaseUrl = 'http://10.0.2.2:8000/api';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// A thin HTTP wrapper that:
/// - Injects Authorization header when a token is present.
/// - Decodes JSON responses.
/// - Throws [ApiException] for non-2xx status codes.
class ApiClient {
  String? _token;

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json',
    };
    if (_token != null) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer $_token';
    }
    return headers;
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$kBaseUrl$path').replace(queryParameters: query);
    final response = await http.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$kBaseUrl$path');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$kBaseUrl$path');
    final response = await http.patch(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<void> delete(String path) async {
    final uri = Uri.parse('$kBaseUrl$path');
    final response = await http.delete(uri, headers: _headers);
    _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    String message = 'Request failed';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message = body['detail'] as String? ?? body.toString();
    } catch (_) {
      message = response.body;
    }

    throw ApiException(response.statusCode, message);
  }
}

// Singleton instance shared across the app.
final apiClient = ApiClient();
