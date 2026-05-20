import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../models/user_model.dart';

class UserService {
  static const _userKey = 'current_user';
  static const _credentialsKey = 'credentials';

  // ── 로컬 저장 / 로드 ──────────────────────────────────────────────────────

  /// 로컬(SharedPreferences)에만 저장. 내부 전용.
  static Future<void> _saveLocal(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  /// 로컬에서 로드. 없으면 null.
  static Future<UserModel?> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  // ── 서버 동기화 ───────────────────────────────────────────────────────────

  /// 서버에서 최신 프로필을 가져와 로컬 캐시에 반영.
  /// 가중치(weightXxx)는 서버에 없으므로 로컬 값을 유지.
  static Future<UserModel?> _fetchFromServer(String email) async {
    final res = await ApiClient.get(
      '/auth/profile',
      params: {'email': email},
    );
    final serverData = res['user'] as Map<String, dynamic>;

    // 로컬 가중치 보존 — 서버에는 weight 필드가 없음
    final local = await _loadLocal();
    final merged = UserModel.fromJson({
      ...serverData,
      'weightMajor': local?.weightMajor ?? 12,
      'weightInterests': local?.weightInterests ?? 20,
      'weightPersonality': local?.weightPersonality ?? 17,
      'weightLanguage': local?.weightLanguage ?? 18,
      'weightPurpose': local?.weightPurpose ?? 25,
      'weightNationality': local?.weightNationality ?? 8,
    });
    await _saveLocal(merged);
    return merged;
  }

  /// 변경된 프로필을 서버에 저장.
  /// 실패해도 로컬 저장은 이미 완료된 상태이므로 예외를 삼킴.
  static Future<void> _pushToServer(UserModel user) async {
    await ApiClient.patch('/auth/profile', {
      'email': user.email,
      'year': user.year,
      'description': user.description,
      if (user.avatarUrl != null && user.avatarUrl!.startsWith('http'))
        'avatar_url': user.avatarUrl,
      'interests': user.interests,
      'exchange_purposes': user.exchangePurposes,
      'personalities': user.personalities,
      'languages': user.languages,
    });
  }

  // ── 공개 API ──────────────────────────────────────────────────────────────

  /// 프로필 저장 — 로컬 저장 후 서버에 동기화.
  /// 서버 연결 실패 시에도 로컬 저장은 유지되므로 에러를 무시.
  static Future<void> saveUser(UserModel user) async {
    await _saveLocal(user);
    try {
      await _pushToServer(user);
    } catch (_) {
      // 서버 저장 실패는 무시 (오프라인/개발 중 서버 미실행 등)
    }
  }

  /// 프로필 로드 — 로컬 캐시 반환 후 서버에서 최신 데이터 동기화.
  /// 서버 연결 실패 시 로컬 캐시를 그대로 반환.
  ///
  /// [syncFromServer]: true면 서버 동기화 시도 (기본값 true).
  static Future<UserModel?> loadUser({bool syncFromServer = true}) async {
    final local = await _loadLocal();
    if (local == null) return null;

    if (!syncFromServer || local.email.isEmpty) return local;

    try {
      return await _fetchFromServer(local.email)
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      return local;
    }
  }

  /// 앱 로그아웃/탈퇴 시 로컬 데이터 전체 삭제.
  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_credentialsKey);
  }

  // ── 자격증명 (로그인 상태 유지) ───────────────────────────────────────────

  static Future<void> saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _credentialsKey, jsonEncode({'email': email, 'password': password}));
  }

  static Future<bool> checkCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_credentialsKey);
    if (raw == null) return false;
    final creds = jsonDecode(raw) as Map<String, dynamic>;
    return creds['email'] == email && creds['password'] == password;
  }
}
