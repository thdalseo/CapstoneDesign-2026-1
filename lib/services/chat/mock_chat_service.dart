import 'dart:async';
import '../../models/chat_message.dart';
import 'chat_service.dart';

/// 백엔드 없이 동작하는 가짜 구현체.
/// 메시지 전송 시 1.2초 후 자동 응답을 흉내낸다.
class MockChatService implements ChatService {
  final _messageController = StreamController<ChatMessage>.broadcast();
  final _stateController = StreamController<ChatConnectionState>.broadcast();

  int _idSeq = 1000;

  @override
  Stream<ChatMessage> get messageStream => _messageController.stream;

  @override
  Stream<ChatConnectionState> get connectionState => _stateController.stream;

  @override
  Future<void> connect(String roomId) async {
    _stateController.add(ChatConnectionState.connecting);
    await Future.delayed(const Duration(milliseconds: 400));
    _stateController.add(ChatConnectionState.connected);
  }

  @override
  Future<void> disconnect() async {
    _stateController.add(ChatConnectionState.disconnected);
  }

  @override
  Future<void> send(String content) async {
    // 보낸 메시지를 스트림에 즉시 추가
    _messageController.add(ChatMessage(
      id: '${_idSeq++}',
      content: content,
      timestamp: DateTime.now(),
      isMe: true,
    ));

    // 상대방 자동 응답 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!_messageController.isClosed) {
      _messageController.add(ChatMessage(
        id: '${_idSeq++}',
        content: '(Mock) 백엔드 연결 후 실제 응답이 표시됩니다.',
        timestamp: DateTime.now(),
        isMe: false,
      ));
    }
  }

  @override
  Future<List<ChatMessage>> fetchHistory(String roomId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    return [
      ChatMessage(
        id: '1',
        content: '안녕하세요! 반가워요 😊',
        timestamp: now.subtract(const Duration(minutes: 10)),
        isMe: false,
      ),
      ChatMessage(
        id: '2',
        content: '저도 반가워요! 잘 부탁드려요 😄',
        timestamp: now.subtract(const Duration(minutes: 8)),
        isMe: true,
      ),
      ChatMessage(
        id: '3',
        content: '같이 이야기 많이 해요!',
        timestamp: now.subtract(const Duration(minutes: 7)),
        isMe: false,
      ),
    ];
  }

  @override
  void dispose() {
    _messageController.close();
    _stateController.close();
  }
}
