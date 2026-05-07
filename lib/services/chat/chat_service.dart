import '../../models/chat_message.dart';

enum ChatConnectionState { disconnected, connecting, connected, error }

/// 채팅 서비스 인터페이스.
/// MockChatService / WebSocketChatService 가 이 계약을 구현한다.
/// ChattingRoomScreen 은 이 타입만 알고, 실제 구현체를 모른다.
abstract class ChatService {
  /// 수신 메시지 스트림 (내가 보낸 메시지 포함 — send() 에서 주입)
  Stream<ChatMessage> get messageStream;

  /// 연결 상태 스트림
  Stream<ChatConnectionState> get connectionState;

  /// [roomId] 채팅방에 연결
  Future<void> connect(String roomId);

  /// 연결 해제
  Future<void> disconnect();

  /// 메시지 전송 — 스트림에 직접 반영 (서버 에코 불필요)
  Future<void> send(String content);

  /// 과거 메시지 로드 (REST 또는 WebSocket 초기 패킷으로 대체 가능)
  Future<List<ChatMessage>> fetchHistory(String roomId);

  /// 리소스 해제
  void dispose();
}
