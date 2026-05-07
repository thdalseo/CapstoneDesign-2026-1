import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../models/match_user.dart';
import '../../services/chat/chat_service.dart';
import '../../services/chat/chat_service_factory.dart';
import '../../theme/app_theme.dart';
import '../../widgets/chatting/chat_bubble.dart';
import '../../widgets/chatting/chat_input_bar.dart';

class ChattingRoomScreen extends StatefulWidget {
  final MatchUser user;

  const ChattingRoomScreen({super.key, required this.user});

  @override
  State<ChattingRoomScreen> createState() => _ChattingRoomScreenState();
}

class _ChattingRoomScreenState extends State<ChattingRoomScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final ChatService _service;
  final List<ChatMessage> _messages = [];
  StreamSubscription<ChatMessage>? _messageSub;
  ChatConnectionState _connState = ChatConnectionState.disconnected;
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _service = ChatServiceFactory.create();
    _init();
  }

  Future<void> _init() async {
    // 연결 상태 구독
    _service.connectionState.listen((state) {
      if (mounted) setState(() => _connState = state);
    });

    // 수신 메시지 구독
    _messageSub = _service.messageStream.listen((msg) {
      if (mounted) {
        setState(() => _messages.add(msg));
        _scrollToBottom();
      }
    });

    // 히스토리 로드 후 연결
    final history = await _service.fetchHistory(widget.user.name);
    if (mounted) {
      setState(() {
        _messages.addAll(history);
        _loadingHistory = false;
      });
    }

    await _service.connect(widget.user.name);
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _service.disconnect();
    _service.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _service.send(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AppTheme.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE8F0FE),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.user.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      widget.user.country,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                _ConnectionLabel(state: _connState),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loadingHistory
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primary,
                      strokeWidth: 2,
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) =>
                        ChatBubble(message: _messages[i]),
                  ),
          ),
          ChatInputBar(
            controller: _controller,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

/// 앱바 아래 연결 상태를 한 줄로 표시
class _ConnectionLabel extends StatelessWidget {
  final ChatConnectionState state;

  const _ConnectionLabel({required this.state});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      ChatConnectionState.connecting => ('연결 중...', AppTheme.textSecondary),
      ChatConnectionState.connected => ('연결됨', AppTheme.mint),
      ChatConnectionState.error => ('연결 오류', AppTheme.coral),
      ChatConnectionState.disconnected => ('오프라인', AppTheme.textSecondary),
    };

    return Text(
      label,
      style: TextStyle(fontSize: 11, color: color),
    );
  }
}
