import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/api_client.dart';
import '../../models/app_notification.dart';
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

  /// 자동 재연결 최대 시도 횟수 / 간격
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 3);

  final String _userId;

  WebSocketChatService({required String myUserId}) : _userId = myUserId;

  // ── 내부 상태 ──────────────────────────────────────────────────────────────
  final _msgCtrl = StreamController<ChatMessage>.broadcast();
  final _stateCtrl = StreamController<ChatConnectionState>.broadcast();
  final _readCtrl = StreamController<DateTime>.broadcast();
  final _errorCtrl = StreamController<String>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription? _wsSub;
  int _localIdSeq = 1;

  String? _currentRoomId; // 재연결에 사용
  bool _disposed = false; // dispose 이후 재연결 방지
  int _retryCount = 0;

  // ── 공개 인터페이스 ────────────────────────────────────────────────────────

  @override
  String get myUserId => _userId;

  @override
  Stream<ChatMessage> get messageStream => _msgCtrl.stream;

  @override
  Stream<ChatConnectionState> get connectionState => _stateCtrl.stream;

  @override
  Stream<DateTime> get readEventStream => _readCtrl.stream;

  @override
  Stream<String> get errorStream => _errorCtrl.stream;

  // ── ChatService 구현 ───────────────────────────────────────────────────────

  @override
  Future<void> connect(String roomId) async {
    _currentRoomId = roomId;
    _retryCount = 0;
    await _doConnect(roomId);
  }

  Future<void> _doConnect(String roomId) async {
    if (_disposed) return;
    _stateCtrl.add(ChatConnectionState.connecting);
    try {
      final uri = Uri.parse('$_wsBase/ws/chat/$roomId');
      _channel = WebSocketChannel.connect(uri);

      // ready를 await 해서 실제 핸드셰이크 완료를 확인
      // web_socket_channel 2.x+ 에서만 지원 — 미지원 시 catch로 넘어감
      await _channel!.ready;

      _retryCount = 0; // 연결 성공 시 재시도 카운터 초기화
      _wsSub = _channel!.stream.listen(
        _onMessage,
        onError: (_) {
          _stateCtrl.add(ChatConnectionState.error);
          _scheduleReconnect();
        },
        onDone: () {
          if (!_disposed) {
            _stateCtrl.add(ChatConnectionState.disconnected);
            _scheduleReconnect();
          }
        },
      );
      _stateCtrl.add(ChatConnectionState.connected);
    } catch (_) {
      _stateCtrl.add(ChatConnectionState.error);
      _scheduleReconnect();
    }
  }

  /// 연결 끊김 시 최대 [_maxRetries]회 재시도 (지수 백오프 없이 고정 3초)
  void _scheduleReconnect() {
    if (_disposed) return;
    if (_currentRoomId == null) return;
    if (_retryCount >= _maxRetries) return; // 최대 횟수 초과 시 포기

    _retryCount++;
    Future.delayed(_retryDelay, () {
      if (!_disposed && _currentRoomId != null) {
        _doConnect(_currentRoomId!);
      }
    });
  }

  @override
  Future<void> disconnect() async {
    _currentRoomId = null;
    _retryCount = _maxRetries; // 재연결 방지
    await _wsSub?.cancel();
    await _channel?.sink.close();
    if (!_disposed) _stateCtrl.add(ChatConnectionState.disconnected);
  }

  @override
  Future<void> send(String content) async {
    // 낙관적 업데이트: 서버 응답 대기 없이 즉시 UI에 반영
    _msgCtrl.add(
      ChatMessage(
        id: 'local_${_localIdSeq++}',
        content: content,
        timestamp: DateTime.now(),
        isMe: true,
      ),
    );
    _channel?.sink.add(
      jsonEncode({'type': 'message', 'sender_id': _userId, 'content': content}),
    );
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
    _disposed = true;
    _currentRoomId = null;
    _msgCtrl.close();
    _stateCtrl.close();
    _readCtrl.close();
    _errorCtrl.close();
  }

  // ── 수신 처리 ──────────────────────────────────────────────────────────────

  void _onMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      if (type == 'message') {
        final notificationJson = data['notification'];
        _msgCtrl.add(
          ChatMessage(
            id: data['id'].toString(),
            content: data['content'] as String,
            timestamp: DateTime.parse(data['timestamp'] as String),
            isMe: false,
            notification: notificationJson is Map<String, dynamic>
                ? AppNotification.fromJson(notificationJson)
                : null,
          ),
        );
      } else if (type == 'read') {
        // 내가 보낸 읽음 이벤트는 무시, 상대방 것만 처리
        final senderStr = data['user_id']?.toString();
        if (senderStr != _userId) {
          final readAt = DateTime.tryParse(data['read_at'] as String? ?? '');
          if (readAt != null) _readCtrl.add(readAt.toLocal());
        }
      } else if (type == 'error') {
        final msg = data['message'] as String? ?? '오류가 발생했어요.';
        // invalid_sender 에러는 errorCtrl에 방출하지 않고 조용히 무시
        // (사용자에게 혼란을 줄 수 있는 기술적 에러)
        if (data['code'] != 'invalid_sender') {
          _errorCtrl.add(msg);
        }
      }
    } catch (_) {
      // 파싱 오류 무시
    }
  }
}
