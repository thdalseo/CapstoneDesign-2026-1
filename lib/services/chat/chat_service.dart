import '../../models/chat_message.dart';

enum ChatConnectionState { disconnected, connecting, connected, error }

/// 채팅 서비스 인터페이스.
/// MockChatService / WebSocketChatService 가 이 계약을 구현한다.
/// ChattingRoomScreen 은 이 타입만 알고, 실제 구현체를 모른다.
abstract class ChatService {
  /// 현재 로그인한 유저 ID
  String get myUserId;

  /// 수신 메시지 스트림 (내가 보낸 메시지 포함 — send() 에서 주입)
  Stream<ChatMessage> get messageStream;

  /// 연결 상태 스트림
  Stream<ChatConnectionState> get connectionState;

  /// 상대방 읽음 이벤트 스트림 (상대방이 읽은 시각 DateTime 방출)
  Stream<DateTime> get readEventStream;

  /// 서버 에러 스트림 (금칙어 등 — 에러 메시지 문자열 방출)
  Stream<String> get errorStream;

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
