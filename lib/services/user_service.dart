import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class UserService {
  static const _userKey = 'current_user';
  static const _credentialsKey = 'credentials';

  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  static Future<UserModel?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_credentialsKey);
  }

  static Future<void> saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_credentialsKey, jsonEncode({'email': email, 'password': password}));
  }

  static Future<bool> checkCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_credentialsKey);
    if (raw == null) return false;
    final creds = jsonDecode(raw) as Map<String, dynamic>;
    return creds['email'] == email && creds['password'] == password;
  }

  // ── 백엔드 API 연동 시 아래 메서드들을 구현하세요 ──────────────────────────
  //
  // static Future<UserModel> fetchProfile(String accessToken) async {
  //   final res = await http.get(
  //     Uri.parse('$baseUrl/api/users/me'),
  //     headers: {'Authorization': 'Bearer $accessToken'},
  //   );
  //   if (res.statusCode != 200) throw Exception('프로필 로드 실패');
  //   return UserModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  // }
  //
  // static Future<void> updateProfile(UserModel user, String accessToken) async {
  //   await http.patch(
  //     Uri.parse('$baseUrl/api/users/me'),
  //     headers: {
  //       'Authorization': 'Bearer $accessToken',
  //       'Content-Type': 'application/json',
  //     },
  //     body: jsonEncode(user.toJson()),
  //   );
  // }
}
