import 'dart:convert';
import 'package:http/http.dart' as http;

const _kBaseUrl = 'http://127.0.0.1:8000';

/// 언어교환 세션 1건의 기록
class SessionRecord {
  final String date;        // "2026-06-02"
  final String teach;       // 가르친 언어
  final String learn;       // 배운 언어
  final int minutes;        // 실제 진행된 분
  final String partnerName; // 상대방 이름

  const SessionRecord({
    required this.date,
    required this.teach,
    required this.learn,
    required this.minutes,
    required this.partnerName,
  });

  factory SessionRecord.fromJson(Map<String, dynamic> j) => SessionRecord(
        date: j['session_date'] as String? ?? j['date'] as String? ?? '',
        teach: j['teach_language'] as String? ?? j['teach'] as String? ?? '',
        learn: j['learn_language'] as String? ?? j['learn'] as String? ?? '',
        minutes: j['minutes'] as int? ?? 0,
        partnerName:
            j['partner_name'] as String? ?? j['partnerName'] as String? ?? '',
      );
}

class SessionHistoryService {
  static const _base = _kBaseUrl;

  /// 세션 1건 서버에 저장
  static Future<void> save({
    required int userId,
    required String teach,
    required String learn,
    required int minutes,
    required String partnerName,
    int? partnerId,
  }) async {
    final body = {
      'user_id': userId,
      if (partnerId != null) 'partner_id': partnerId,
      'partner_name': partnerName,
      'teach_language': teach,
      'learn_language': learn,
      'minutes': minutes,
      'session_date': todayKey(),
    };
    try {
      await http.post(
        Uri.parse('$_base/api/sessions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } catch (_) {
      // 네트워크 오류 → 조용히 무시 (기록 실패해도 채팅에 영향 없음)
    }
  }

  /// 서버에서 전체 기록 로드
  static Future<List<SessionRecord>> loadAll(int userId) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/api/sessions?user_id=$userId'),
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list
            .whereType<Map<String, dynamic>>()
            .map(SessionRecord.fromJson)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// 날짜별 기록 맵 반환 {"2026-06-02": [records...]}
  static Future<Map<String, List<SessionRecord>>> groupByDate(int userId) async {
    final all = await loadAll(userId);
    final map = <String, List<SessionRecord>>{};
    for (final r in all) {
      map.putIfAbsent(r.date, () => []).add(r);
    }
    return map;
  }

  /// 오늘 날짜 문자열 "yyyy-MM-dd"
  static String todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// DateTime → "yyyy-MM-dd"
  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
