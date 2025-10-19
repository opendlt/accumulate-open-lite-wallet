// Core networking service - no Flutter dependencies
import 'dart:convert';
import 'package:http/http.dart' as http;

class NetworkService {
  final Duration timeout;

  NetworkService({
    this.timeout =
        const Duration(seconds: 20), // Healthy APIs should respond within 20s
  });

  /// Generic GET request
  Future<NetworkResult> get(String url, {Map<String, String>? headers}) async {
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(timeout);

      return NetworkResult(
        success: response.statusCode >= 200 && response.statusCode < 300,
        statusCode: response.statusCode,
        data: response.body,
        headers: response.headers,
      );
    } catch (e) {
      return NetworkResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Generic POST request
  Future<NetworkResult> post(
    String url, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: headers ?? {'Content-Type': 'application/json'},
            body: body is String ? body : jsonEncode(body),
          )
          .timeout(timeout);

      return NetworkResult(
        success: response.statusCode >= 200 && response.statusCode < 300,
        statusCode: response.statusCode,
        data: response.body,
        headers: response.headers,
      );
    } catch (e) {
      return NetworkResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Generic PUT request
  Future<NetworkResult> put(
    String url, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse(url),
            headers: headers ?? {'Content-Type': 'application/json'},
            body: body is String ? body : jsonEncode(body),
          )
          .timeout(timeout);

      return NetworkResult(
        success: response.statusCode >= 200 && response.statusCode < 300,
        statusCode: response.statusCode,
        data: response.body,
        headers: response.headers,
      );
    } catch (e) {
      return NetworkResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Generic DELETE request
  Future<NetworkResult> delete(String url,
      {Map<String, String>? headers}) async {
    try {
      final response = await http
          .delete(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(timeout);

      return NetworkResult(
        success: response.statusCode >= 200 && response.statusCode < 300,
        statusCode: response.statusCode,
        data: response.body,
        headers: response.headers,
      );
    } catch (e) {
      return NetworkResult(
        success: false,
        error: e.toString(),
      );
    }
  }
}

class NetworkResult {
  final bool success;
  final int? statusCode;
  final String? data;
  final Map<String, String>? headers;
  final String? error;

  const NetworkResult({
    required this.success,
    this.statusCode,
    this.data,
    this.headers,
    this.error,
  });

  /// Parse response data as JSON
  Map<String, dynamic>? get jsonData {
    if (data == null) return null;
    try {
      return jsonDecode(data!);
    } catch (e) {
      return null;
    }
  }
}
