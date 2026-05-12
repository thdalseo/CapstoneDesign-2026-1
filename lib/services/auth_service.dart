import '../core/api_client.dart';
import '../models/user_model.dart';
import 'user_service.dart';

class AuthService {
  /// 이메일로 인증 코드 발송
  static Future<void> sendCode(String email) async {
    await ApiClient.post('/auth/send-code', {'email': email});
  }

  /// 인증 코드 검증 + 회원가입 완료 → 로컬에 유저 저장
  static Future<UserModel> register({
    required String email,
    required String code,
    required String password,
    required String name,
    required String country,
    required String college,
    required String major,
  }) async {
    final res = await ApiClient.post('/auth/register', {
      'email': email,
      'code': code,
      'password': password,
      'name': name,
      'country': country,
      'college': college,
      'major': major,
    });

    final user = UserModel.fromJson(res['user'] as Map<String, dynamic>);
    await UserService.saveUser(user);
    return user;
  }

  /// 로그인 → 로컬에 유저 저장
  static Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final res = await ApiClient.post('/auth/login', {
      'email': email,
      'password': password,
    });

    final user = UserModel.fromJson(res['user'] as Map<String, dynamic>);
    await UserService.saveUser(user);
    return user;
  }
}
