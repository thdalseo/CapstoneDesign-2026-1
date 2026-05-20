import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/api_client.dart';
import '../../models/chat_message.dart';
import 'chat_service.dart';

/// 실제 백엔드(FastAPI WebSocket)와 통신하는 구현체.
///
/// 서버 주소:
///   - 웹 / iOS 시뮬레이터 / 데스크톱: ws://127.0.0.1:8000
///   - Android 에뮬레이터: ws://10.0.2.2:8000  (에뮬레이터 전용 루프백)
///   - 실기기 (같은 Wi-Fi): ws://PC_IP:8000
class WebSocketChatService implements ChatService {
  static const String _wsBase  = 'ws://127.0.0.1:8000';

  /// 현재 로그인한 유저의 DB id (String).
  /// ApiClient / UserService 에서 주입받는다.
  final String myUserId;

  WebSocketChatService({required this.myUserId});

  // ── 내부 상태 ────────────────────────────────────────────────────────────────
  final _msgCtrl   = StreamController<ChatMessage>.broadcast();
  final _stateCtrl = StreamController<ChatConnectionState>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription? _wsSub;
  int _localIdSeq = 1;

  // ── 공개 스트림 ───────────────────────────────────────────────────────────────

  @override
  Stream<ChatMessage> get messageStream => _msgCtrl.stream;

  @override
  Stream<ChatConnectionState> get connectionState => _stateCtrl.stream;

  // ── ChatService 구현 ──────────────────────────────────────────────────────────

  @override
  Future<void> connect(String roomId) async {
    _stateCtrl.add(ChatConnectionState.connecting);
    try {
      final uri = Uri.parse('$_wsBase/ws/chat/$roomId');
      _channel = WebSocketChannel.connect(uri);

      _wsSub = _channel!.stream.listen(
        _onMessage,
        onError: (_) => _stateCtrl.add(ChatConnectionState.error),
        onDone:  () => _stateCtrl.add(ChatConnectionState.disconnected),
      );
      _stateCtrl.add(ChatConnectionState.connected);
    } catch (_) {
      _stateCtrl.add(ChatConnectionState.error);
    }
  }

  @override
  Future<void> disconnect() async {
    await _wsSub?.cancel();
    await _channel?.sink.close();
    _stateCtrl.add(ChatConnectionState.disconnected);
  }

  @override
  Future<void> send(String content) async {
    // 낙관적 업데이트: 서버 응답 대기 없이 즉시 UI에 반영
    _msgCtrl.add(ChatMessage(
      id: 'local_${_localIdSeq++}',
      content: content,
      timestamp: DateTime.now(),
      isMe: true,
    ));

    // 서버로 전송 (서버는 보낸 사람을 제외하고 브로드캐스트)
    _channel?.sink.add(jsonEncode({
      'type': 'message',
      'sender_id': myUserId,
      'content': content,
    }));
  }

  @override
  Future<List<ChatMessage>> fetchHistory(String roomId) async {
    try {
      final list = await ApiClient.getList('/chat/rooms/$roomId/messages');
      return list.map((json) {
        final j = json as Map<String, dynamic>;
        return ChatMessage(
          id: j['id'].toString(),
          content: j['content'] as String,
          timestamp: DateTime.parse(j['timestamp'] as String),
          isMe: j['sender_id']?.toString() == myUserId,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  void dispose() {
    _msgCtrl.close();
    _stateCtrl.close();
  }

  // ── 수신 처리 ─────────────────────────────────────────────────────────────────

  /// 서버에서 브로드캐스트된 메시지 수신.
  /// 서버는 보낸 사람을 제외하고 전송하므로 여기서 받는 메시지는 상대방 것.
  void _onMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      if (data['type'] != 'message') return;

      _msgCtrl.add(ChatMessage(
        id: data['id'].toString(),
        content: data['content'] as String,
        timestamp: DateTime.parse(data['timestamp'] as String),
        isMe: false, // 서버가 exclude 처리했으므로 항상 상대방 메시지
      ));
    } catch (_) {
      // 파싱 오류 무시
    }
  }
}
