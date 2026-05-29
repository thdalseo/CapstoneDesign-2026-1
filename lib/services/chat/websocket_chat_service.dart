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
///   - Android 에뮬레이터: ws://10.0.2.2:8000
///   - 실기기 (같은 Wi-Fi): ws://PC_IP:8000
class WebSocketChatService implements ChatService {
  static const String _wsBase = 'ws://127.0.0.1:8000';

  final String _userId;

  WebSocketChatService({required String myUserId}) : _userId = myUserId;

  // ── 내부 상태 ──────────────────────────────────────────────────────────────
  final _msgCtrl   = StreamController<ChatMessage>.broadcast();
  final _stateCtrl = StreamController<ChatConnectionState>.broadcast();
  final _readCtrl  = StreamController<DateTime>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription? _wsSub;
  int _localIdSeq = 1;

  // ── 공개 인터페이스 ────────────────────────────────────────────────────────

  @override
  String get myUserId => _userId;

  @override
  Stream<ChatMessage> get messageStream => _msgCtrl.stream;

  @override
  Stream<ChatConnectionState> get connectionState => _stateCtrl.stream;

  @override
  Stream<DateTime> get readEventStream => _readCtrl.stream;

  // ── ChatService 구현 ───────────────────────────────────────────────────────

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
    _channel?.sink.add(jsonEncode({
      'type': 'message',
      'sender_id': _userId,
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
          isMe: j['sender_id']?.toString() == _userId,
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
    _readCtrl.close();
  }

  // ── 수신 처리 ──────────────────────────────────────────────────────────────

  void _onMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      if (type == 'message') {
        _msgCtrl.add(ChatMessage(
          id: data['id'].toString(),
          content: data['content'] as String,
          timestamp: DateTime.parse(data['timestamp'] as String),
          isMe: false,
        ));
      } else if (type == 'read') {
        // 내가 보낸 읽음 이벤트는 무시, 상대방 것만 처리
        final senderStr = data['user_id']?.toString();
        if (senderStr != _userId) {
          final readAt = DateTime.tryParse(data['read_at'] as String? ?? '');
          if (readAt != null) _readCtrl.add(readAt.toLocal());
        }
      }
    } catch (_) {
      // 파싱 오류 무시
    }
  }
}
