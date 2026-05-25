import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../models/chat_message.dart';
import '../../models/match_user.dart';
import '../../models/user_model.dart';
import '../../services/chat/chat_service.dart';
import '../../services/chat/chat_service_factory.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/chatting/chat_bubble.dart';
import '../../widgets/chatting/chat_input_bar.dart';

class ChattingRoomScreen extends StatefulWidget {
  final MatchUser user;
  final String? initialMessage;

  const ChattingRoomScreen({
    super.key,
    required this.user,
    this.initialMessage,
  });

  @override
  State<ChattingRoomScreen> createState() => _ChattingRoomScreenState();
}

class _ChattingRoomScreenState extends State<ChattingRoomScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  ChatService? _service;        // 비동기 초기화 전까지 null
  final List<ChatMessage> _messages = [];
  StreamSubscription<ChatMessage>? _messageSub;
  ChatConnectionState _connState = ChatConnectionState.disconnected;
  bool _loadingHistory = true;
  bool _showSuggestions = true;

  // AI 아이스브레이킹 제안
  List<String> _suggestions = const [];
  bool _loadingSuggestions = true;
  UserModel? _myUser;

  @override
  void initState() {
    super.initState();
    _init();
    // context.locale 접근은 첫 빌드 이후에 가능
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchSuggestions());
  }

  /// 1) 서비스 생성  2) 채팅방 ID 확보  3) 히스토리 로드  4) WebSocket 연결
  Future<void> _init() async {
    // ── 1. 서비스 생성 (myUserId 포함) ──────────────────────────────────────
    final svc = await ChatServiceFactory.create();
    if (!mounted) return;
    _service = svc;

    // 내 프로필 로드 (아이스브레이킹용)
    _myUser = await UserService.loadUser(syncFromServer: false);

    _service!.connectionState.listen((state) {
      if (mounted) setState(() => _connState = state);
    });
    _messageSub = _service!.messageStream.listen((msg) {
      if (mounted) {
        setState(() => _messages.add(msg));
        _scrollToBottom();
      }
    });

    // ── 2. 채팅방 ID 확보 ────────────────────────────────────────────────────
    final roomId = await _resolveRoomId();
    if (!mounted) return;

    // ── 3. 메시지 히스토리 로드 ──────────────────────────────────────────────
    final history = await _service!.fetchHistory(roomId);
    if (mounted) {
      setState(() {
        _messages.addAll(history);
        _loadingHistory = false;
      });
    }

    // ── 4. WebSocket 연결 ────────────────────────────────────────────────────
    await _service!.connect(roomId);

    // ── 5. 초기 메시지 전송 (도움 화면에서 진입 시) ─────────────────────────
    if (widget.initialMessage != null && mounted) {
      _service!.send(widget.initialMessage!);
      _scrollToBottom();
    }
  }

  /// 두 유저의 채팅방 ID를 REST API로 확보.
  /// 서버 연결 불가 또는 ID 미확정 시 상대방 user.id(또는 name)를 fallback으로 사용.
  Future<String> _resolveRoomId() async {
    try {
      final me = await UserService.loadUser(syncFromServer: false);
      final myId = int.tryParse(me?.id ?? '') ?? 0;
      final otherId = int.tryParse(widget.user.id) ?? 0;

      if (myId > 0 && otherId > 0) {
        final res = await ApiClient.post('/chat/rooms', {
          'user_id_a': myId,
          'user_id_b': otherId,
        });
        return res['room_id'].toString();
      }
    } catch (_) {
      // 서버 미연결 / ID 미확정 → fallback
    }
    // fallback: 목(mock) 또는 개발 중일 때
    return widget.user.id.isNotEmpty ? widget.user.id : widget.user.name;
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _service?.disconnect();
    _service?.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_service == null) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    if (_showSuggestions) setState(() => _showSuggestions = false);
    _service!.send(text);
    _scrollToBottom();
  }

  void _sendSuggestion(String text) {
    if (_service == null) return;
    setState(() => _showSuggestions = false);
    _service!.send(text);
    _scrollToBottom();
  }

  Future<void> _refreshSuggestions() async {
    if (!mounted) return;
    setState(() => _loadingSuggestions = true);
    await _fetchSuggestions();
  }

  Widget _buildEmptyWithSuggestions() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE8F0FE),
            ),
            child: const Icon(
              Icons.waving_hand_rounded,
              color: AppTheme.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'chat.greeting'.tr(namedArgs: {'name': widget.user.name}),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'chat.suggestion_desc'.tr(),
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더: 라벨 + AI 배지 + 새로고침 + 닫기
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Text(
                  'chat.suggestion_label'.tr(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                if (_loadingSuggestions)
                  const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppTheme.primary,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 9, color: AppTheme.primary),
                        SizedBox(width: 3),
                        Text(
                          'AI',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                // 새로고침 버튼
                GestureDetector(
                  onTap: _loadingSuggestions ? null : _refreshSuggestions,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.refresh_rounded,
                      size: 15,
                      color: _loadingSuggestions
                          ? AppTheme.textSecondary.withValues(alpha: 0.4)
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                // 닫기 버튼
                GestureDetector(
                  onTap: () => setState(() => _showSuggestions = false),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 15,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 제안 칩 목록
          if (_loadingSuggestions)
            // 로딩 중: 스켈레톤 플레이스홀더
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(3, (i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    width: 120 + i * 20.0,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                )),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _suggestions.map((text) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _sendSuggestion(text),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4FF),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          text,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  /// 서버에서 AI 아이스브레이킹 질문을 받아온다.
  /// 실패 시 로컬 fallback(번역 JSON)을 사용한다.
  Future<void> _fetchSuggestions() async {
    if (!mounted) return;
    final locale = context.locale.languageCode;
    final me = _myUser;

    try {
      final res = await ApiClient.post('/chat/icebreaking', {
        'my_name': me?.name ?? '',
        'my_country': me?.countryName ?? '',
        'my_major': me?.major ?? '',
        'my_interests': me?.interests ?? [],
        'my_purposes': me?.exchangePurposes ?? [],
        'my_personalities': me?.personalities ?? [],
        'weight_purpose': me?.weightPurpose ?? 25,
        'weight_interests': me?.weightInterests ?? 20,
        'weight_language': me?.weightLanguage ?? 18,
        'weight_personality': me?.weightPersonality ?? 17,
        'weight_major': me?.weightMajor ?? 8,
        'weight_year': me?.weightYear ?? 7,
        'weight_nationality': me?.weightNationality ?? 5,
        'other_name': widget.user.name,
        'other_country': widget.user.countryName,
        'other_major': widget.user.major,
        'other_interests': widget.user.interests,
        'locale': locale,
      });

      final questions = (res['questions'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [];

      if (mounted) {
        setState(() {
          _suggestions = questions.isNotEmpty ? questions : _fallbackSuggestions();
          _loadingSuggestions = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _suggestions = _fallbackSuggestions();
          _loadingSuggestions = false;
        });
      }
    }
  }

  /// 번역 JSON 기반 정적 fallback 제안
  List<String> _fallbackSuggestions() {
    return List.generate(6, (i) => 'chat.suggestions[$i]'.tr());
  }

=======
>>>>>>> 281480d (feat: 아이스브레이킹 개선 및 매칭 상태 저장)
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
                : _messages.isEmpty
                    ? _buildEmptyWithSuggestions()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) =>
                            ChatBubble(message: _messages[i]),
                      ),
          ),
          if (!_loadingHistory && _showSuggestions) _buildSuggestionChips(),
          ChatInputBar(
            controller: _controller,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

/// 앱바 연결 상태 표시
class _ConnectionLabel extends StatelessWidget {
  final ChatConnectionState state;

  const _ConnectionLabel({required this.state});

  @override
  Widget build(BuildContext context) {
    final (key, color) = switch (state) {
      ChatConnectionState.connecting =>
        ('chat.connecting', AppTheme.textSecondary),
      ChatConnectionState.connected => ('chat.connected', AppTheme.mint),
      ChatConnectionState.error => ('chat.conn_error', AppTheme.coral),
      ChatConnectionState.disconnected =>
        ('chat.offline', AppTheme.textSecondary),
    };

    return Text(
      key.tr(),
      style: TextStyle(fontSize: 11, color: color),
    );
  }
}
