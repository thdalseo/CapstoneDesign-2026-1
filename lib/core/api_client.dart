import 'dart:convert';
import 'package:http/http.dart' as http;

/// 개발 환경 서버 주소
/// - 웹 / iOS 시뮬레이터: http://127.0.0.1:8000
/// - Android 에뮬레이터: http://10.0.2.2:8000
/// - 실기기 (같은 Wi-Fi): http://192.168.x.x:8000
const String _baseUrl = 'http://127.0.0.1:8000';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiClient {
  static Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? params,
  }) async {
    final uri = Uri.parse('$_baseUrl$path')
        .replace(queryParameters: params);
    final res = await http.get(uri, headers: {'Content-Type': 'application/json'});

    final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) return decoded;

    final detail = decoded['detail']?.toString() ?? '서버 오류가 발생했습니다.';
    throw ApiException(res.statusCode, detail);
  }

  /// GET 요청으로 JSON 배열을 반환하는 엔드포인트용
  static Future<List<dynamic>> getList(
    String path, {
    Map<String, String>? params,
  }) async {
    final uri = Uri.parse('$_baseUrl$path')
        .replace(queryParameters: params);
    final res = await http.get(uri, headers: {'Content-Type': 'application/json'});

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    }

    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    final detail = (decoded as Map?)?['detail']?.toString() ?? '서버 오류가 발생했습니다.';
    throw ApiException(res.statusCode, detail);
  }

  static Future<Map<String, dynamic>> patch(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final uri = Uri.parse('$_baseUrl$path');
    final res = await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body != null ? jsonEncode(body) : null,
    );

    final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) return decoded;

    final detail = decoded['detail']?.toString() ?? '서버 오류가 발생했습니다.';
    throw ApiException(res.statusCode, detail);
  }

  static Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$_baseUrl$path');
    final res = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) return decoded;

    final detail = decoded['detail']?.toString() ?? '서버 오류가 발생했습니다.';
    throw ApiException(res.statusCode, detail);
  }

  static Future<Map<String, dynamic>> delete(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$_baseUrl$path');
    final res = await http.delete(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }

    final detail = decoded['detail']?.toString() ?? '서버 오류가 발생했습니다.';
    throw ApiException(res.statusCode, detail);
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$_baseUrl$path');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }

    // FastAPI 에러 응답: {"detail": "..."}
    final detail = decoded['detail']?.toString() ?? '서버 오류가 발생했습니다.';
    throw ApiException(res.statusCode, detail);
  }
}
