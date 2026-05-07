import 'dart:async';
import 'dart:convert';
// TODO: pubspec.yaml 에 web_socket_channel: ^2.4.0 추가 후 아래 주석 해제
// import 'package:web_socket_channel/web_socket_channel.dart';
import '../../models/chat_message.dart';
import 'chat_service.dart';

/// WebSocket 기반 실제 구현체.
///
/// 백엔드 준비 시 체크리스트:
///   1. pubspec.yaml 에 web_socket_channel: ^2.4.0 추가 → flutter pub get
///   2. [_wsBaseUrl] 을 실제 서버 주소로 교체  (예: ws://api.yourapp.com/ws/chat)
///   3. [_myUserId] 를 인증 서비스에서 가져오도록 교체
///   4. 서버 메시지 JSON 스키마에 맞게 _parseIncoming() 수정
///   5. ChatServiceFactory._useMock 을 false 로 변경
class WebSocketChatService implements ChatService {
  // ── 서버 설정 ───────────────────────────────────────────────
  // ignore: unused_field
  static const String _wsBaseUrl = 'ws://localhost:8080/ws/chat';
  static const String _myUserId = 'me';
  // ────────────────────────────────────────────────────────────

  final _messageController = StreamController<ChatMessage>.broadcast();
  final _stateController = StreamController<ChatConnectionState>.broadcast();

  // WebSocketChannel? _channel;   // ← 주석 해제 필요
  StreamSubscription? _wsSub;
  int _idSeq = 1;
  // ignore: unused_field
  String _roomId = '';

  @override
  Stream<ChatMessage> get messageStream => _messageController.stream;

  @override
  Stream<ChatConnectionState> get connectionState => _stateController.stream;

  @override
  Future<void> connect(String roomId) async {
    _roomId = roomId;
    _stateController.add(ChatConnectionState.connecting);

    try {
      // TODO: 아래 두 줄 주석 해제
      // final uri = Uri.parse('$_wsBaseUrl/$roomId');
      // _channel = WebSocketChannel.connect(uri);

      // TODO: 인증 헤더 필요 시 WebSocketChannel.connect(uri, protocols: [...]) 활용

      // _wsSub = _channel!.stream.listen(
      //   _parseIncoming,
      //   onError: (e) => _stateController.add(ChatConnectionState.error),
      //   onDone: () => _stateController.add(ChatConnectionState.disconnected),
      // );

      _stateController.add(ChatConnectionState.connected);
    } catch (_) {
      _stateController.add(ChatConnectionState.error);
    }
  }

  @override
  Future<void> disconnect() async {
    await _wsSub?.cancel();
    // _channel?.sink.close();   // ← 주석 해제 필요
    _stateController.add(ChatConnectionState.disconnected);
  }

  @override
  Future<void> send(String content) async {
    final msg = ChatMessage(
      id: '${_idSeq++}',
      content: content,
      timestamp: DateTime.now(),
      isMe: true,
    );

    // 서버 전송 전에 UI 에 즉시 반영 (낙관적 업데이트)
    _messageController.add(msg);

    // TODO: 아래 주석 해제
    // _channel?.sink.add(jsonEncode({
    //   'type': 'message',
    //   'roomId': _roomId,
    //   'senderId': _myUserId,
    //   'content': content,
    //   'timestamp': msg.timestamp.toIso8601String(),
    // }));
  }

  @override
  Future<List<ChatMessage>> fetchHistory(String roomId) async {
    // TODO: REST API 또는 WebSocket 초기 패킷으로 히스토리 로드
    // 예시 (http 패키지 사용):
    // final res = await http.get(Uri.parse('https://api.yourapp.com/rooms/$roomId/messages'));
    // final list = jsonDecode(res.body) as List;
    // return list.map(_parseMessage).toList();
    return [];
  }

  /// 서버에서 수신한 JSON 문자열을 파싱해 스트림에 추가
  // ignore: unused_element
  void _parseIncoming(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;

      // TODO: 서버 스키마에 맞게 필드명 수정
      if (data['type'] == 'message') {
        _messageController.add(ChatMessage(
          id: data['id'] as String,
          content: data['content'] as String,
          timestamp: DateTime.parse(data['timestamp'] as String),
          isMe: (data['senderId'] as String) == _myUserId,
        ));
      }
    } catch (_) {
      // 파싱 오류는 조용히 무시 (필요 시 로깅 추가)
    }
  }

  @override
  void dispose() {
    _messageController.close();
    _stateController.close();
  }
}
