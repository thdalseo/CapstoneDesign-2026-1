import 'dart:convert';
import 'package:http/http.dart' as http;

/// 개발 환경 서버 주소
<<<<<<< HEAD
/// - 웹 / iOS 시뮬레이터: http://127.0.0.1:8000
/// - Android 에뮬레이터: http://10.0.2.2:8000
/// - 실기기 (같은 Wi-Fi): http://192.168.x.x:8000
=======
/// - Android 에뮬레이터: 10.0.2.2:8000
/// - iOS 시뮬레이터 / 웹: localhost:8000
/// - 실기기: 같은 Wi-Fi의 PC IP (예: 192.168.0.10:8000)
>>>>>>> d2950ad090eaefb70e2143adda888c6b6325a3c5
const String _baseUrl = 'http://127.0.0.1:8000';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiClient {
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

<<<<<<< HEAD
=======
    // FastAPI 에러 응답: {"detail": "..."}
>>>>>>> d2950ad090eaefb70e2143adda888c6b6325a3c5
    final detail = decoded['detail']?.toString() ?? '서버 오류가 발생했습니다.';
    throw ApiException(res.statusCode, detail);
  }
}
