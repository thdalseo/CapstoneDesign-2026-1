import 'chat_service.dart';
import 'mock_chat_service.dart';
import 'websocket_chat_service.dart';

/// 백엔드 연결 시 [_useMock] 을 false 로 바꾸는 것 하나면 전환 완료.
/// 화면/위젯 코드는 전혀 수정할 필요 없다.
class ChatServiceFactory {
  static const bool _useMock = true; // ← 백엔드 준비 시 false 로 변경

  static ChatService create() =>
      _useMock ? MockChatService() : WebSocketChatService();
}
