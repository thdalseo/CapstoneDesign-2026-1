import '../user_service.dart';
import 'chat_service.dart';
import 'mock_chat_service.dart';
import 'websocket_chat_service.dart';

/// 채팅 서비스 팩토리.
///
/// [_useMock] = true  → 백엔드 없이 MockChatService (자동 응답 시뮬레이션)
/// [_useMock] = false → 실제 WebSocket 연결 (WebSocketChatService)
class ChatServiceFactory {
  static const bool _useMock = false; // ← mock 모드로 되돌리려면 true

  /// 비동기 생성: WebSocket 모드에서는 현재 유저 ID를 로드한다.
  static Future<ChatService> create() async {
    if (_useMock) return MockChatService();

    // SharedPreferences에서 유저 정보 로드 (서버 동기화 없이 빠르게)
    final user = await UserService.loadUser(syncFromServer: false);
    return WebSocketChatService(myUserId: user?.id ?? '');
  }
}
