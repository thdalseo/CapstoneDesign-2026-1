import 'dart:async';
import 'dart:math' as math;
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
import '../../constants/profile_labels.dart';
import '../../services/session_history_service.dart';
import '../../utils/avatar_color.dart';
import '../../widgets/chatting/chat_bubble.dart';
import '../../widgets/chatting/chat_input_bar.dart';

class ChattingRoomScreen extends StatefulWidget {
  final MatchUser user;
  final String? initialMessage;
  final int? roomId; // 채팅 목록에서 진입 시 미리 알고 있는 room_id

  const ChattingRoomScreen({
    super.key,
    required this.user,
    this.initialMessage,
    this.roomId,
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
  StreamSubscription<DateTime>? _readSub;
  StreamSubscription<String>? _errorSub;
  ChatConnectionState _connState = ChatConnectionState.disconnected;
  bool _loadingHistory = true;
  bool _showSuggestions = true;
  int? _resolvedRoomId;         // 서버에서 확정된 room_id
  DateTime? _otherLastReadAt;   // 상대방이 마지막으로 읽은 시각

  // AI 아이스브레이킹 제안
  List<String> _suggestions = const [];
  bool _loadingSuggestions = true;
  UserModel? _myUser;

  // AI 문장 교정
  bool _correcting = false;

  // 언어교환 세션 타이머
  Timer? _sessionTimer;
  int _sessionRemainingSeconds = 0;
  int _sessionTotalSeconds = 0; // 총 설정 시간 (저장 시 사용)
  String _sessionTeach = '';
  String _sessionLearn = '';
  bool get _sessionActive => _sessionRemainingSeconds > 0;
  bool _sessionDone = false; // 세션 완료 여부 (카드 UI 반영용)

  @override
  void initState() {
    super.initState();
    _init();
    // context.locale 접근은 첫 빌드 이후에 가능
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchSuggestions());
  }

  /// 초기화 순서:
  /// 1) 서비스 생성  2) roomId + 프로필 병렬  3) WebSocket 연결
  /// 4) 읽음상태 조회(fire&forget)  5) 히스토리 로드  6) 읽음처리(fire&forget)
  Future<void> _init() async {
    // ── 1. 서비스 생성 ───────────────────────────────────────────────────────
    final svc = await ChatServiceFactory.create();
    if (!mounted) return;
    _service = svc;

    _service!.connectionState.listen((state) {
      if (mounted) setState(() => _connState = state);
    });
    _messageSub = _service!.messageStream.listen((msg) {
      if (!mounted) return;
      // ── 세션 명령 메시지 처리 (화면에 표시하지 않음) ──
      if (msg.content.startsWith('__SESSION_START__|')) {
        final parts = msg.content.split('|');
        final teach = parts.length > 1 ? parts[1].split(':').skip(1).join(':') : '';
        final learn = parts.length > 2 ? parts[2].split(':').skip(1).join(':') : '';
        final minutes = parts.length > 3 ? int.tryParse(parts[3].split(':').last) ?? 30 : 30;
        if (!_sessionActive) _startSessionTimer(teach, learn, minutes);
        return;
      }
      if (msg.content == '__SESSION_STOP__') {
        if (_sessionActive) {
          _sessionTimer?.cancel();
          _onSessionComplete(autoFinished: false, notify: false);
        } else if (!_sessionDone) {
          setState(() => _sessionDone = true);
        }
        return;
      }
      if (msg.content.startsWith('__LANG_SESSION__|')) {
        setState(() => _sessionDone = false);
      }
      setState(() => _messages.add(msg));
      _scrollToBottom();
    });
    _readSub = _service!.readEventStream.listen((readAt) {
      if (mounted) setState(() => _otherLastReadAt = readAt);
    });
    _errorSub = _service!.errorStream.listen((msg) {
      if (!mounted) return;
      // 낙관적으로 추가된 마지막 내 메시지 제거 (금칙어 롤백)
      setState(() {
        final idx = _messages.lastIndexWhere((m) => m.isMe);
        if (idx != -1) _messages.removeAt(idx);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    });

    // ── 2. roomId 확보 + 내 프로필 로드 (병렬) ──────────────────────────────
    final results = await Future.wait([
      _resolveRoomId(),
      UserService.loadUser(syncFromServer: false),
    ]);
    if (!mounted) return;

    final roomId = results[0] as String;
    _myUser = results[1] as UserModel?;
    setState(() => _resolvedRoomId = int.tryParse(roomId));

    final myId = int.tryParse(_service!.myUserId) ?? 0;

    // ── 3. WebSocket 연결 먼저 (이후 서버 브로드캐스트를 받을 준비) ──────────
    await _service!.connect(roomId);

    // ── 4. 상대방 읽음 상태 조회 (히스토리와 동시, DB 읽기만) ────────────────
    if (myId > 0) _fetchOtherReadStatus(roomId, myId);

    // ── 5. 메시지 히스토리 로드 ──────────────────────────────────────────────
    final history = await _service!.fetchHistory(roomId);
    if (!mounted) return;

    // 세션 명령 메시지(__SESSION_START__, __SESSION_STOP__)는 화면에 표시하지 않음
    final visibleHistory = history.where((m) =>
        !m.content.startsWith('__SESSION_START__|') &&
        m.content != '__SESSION_STOP__').toList();

    // 마지막 세션 카드 이후 __SESSION_STOP__이 있으면 완료 상태 복원
    final lastSessionIdx = history.lastIndexWhere(
        (m) => m.content.startsWith('__LANG_SESSION__|'));
    final lastStopIdx = history.lastIndexWhere(
        (m) => m.content == '__SESSION_STOP__');
    final restoredDone = lastSessionIdx != -1 && lastStopIdx > lastSessionIdx;

    setState(() {
      _messages.addAll(visibleHistory);
      _loadingHistory = false;
      if (restoredDone) _sessionDone = true;
    });
    _scrollToBottom(); // 최신 메시지로 이동

    // ── 6. 읽음 처리 (메시지 화면에 표시된 후 — DB 쓰기 경합 방지) ───────────
    if (myId > 0) _markAsRead(roomId, myId);

    // ── 7. 초기 메시지 전송 (도움 화면에서 진입 시) ─────────────────────────
    if (widget.initialMessage != null && mounted) {
      _service!.send(widget.initialMessage!);
      _scrollToBottom();
    }
  }

  /// 두 유저의 채팅방 ID를 확보.
  /// 채팅 목록에서 진입 시 widget.roomId를 바로 사용해 서버 왕복을 줄인다.
  Future<String> _resolveRoomId() async {
    // 이미 알고 있는 roomId가 있으면 즉시 반환 (불필요한 서버 호출 생략)
    if (widget.roomId != null && widget.roomId! > 0) {
      return widget.roomId!.toString();
    }
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
    // fallback: 서버 미연결 / ID 미확정 시 '0' 반환
    // → connect('0')은 실패하고 error 상태로 전환되어 UI에 명확히 표시됨
    return '0';
  }

  @override
  void dispose() {
    // 채팅방 나갈 때 세션이 진행 중이면 경과 시간 저장
    if (_sessionActive) _saveSessionRecord();
    _messageSub?.cancel();
    _readSub?.cancel();
    _errorSub?.cancel();
    _sessionTimer?.cancel();
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

  /// ✨ 버튼 — AI 문장 교정 요청 후 바텀시트 표시
  Future<void> _correctMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _correcting) return;

    setState(() => _correcting = true);

    try {
      final locale = mounted ? context.locale.languageCode : 'ko';
      final res = await ApiClient.post('/chat/correct', {
        'text': text,
        'locale': locale,
      });

      if (!mounted) return;

      final isCorrect = res['is_correct'] as bool? ?? true;
      final corrected = res['corrected'] as String? ?? text;
      final explanation = res['explanation'] as String? ?? '';

      _showCorrectionSheet(
        original: text,
        corrected: corrected,
        isCorrect: isCorrect,
        explanation: explanation,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('chat.correct_error'.tr()),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _correcting = false);
    }
  }

  void _showCorrectionSheet({
    required String original,
    required String corrected,
    required bool isCorrect,
    required String explanation,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 드래그 핸들
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 헤더
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 16, color: AppTheme.primary),
                const SizedBox(width: 6),
                Text(
                  'chat.correct_title'.tr(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (isCorrect) ...[
              // 이미 자연스러운 경우
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.mint.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.mint.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        size: 18, color: AppTheme.mint),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'chat.correct_already_good'.tr(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _sendMessage();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('chat.correct_send_original'.tr(),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ] else ...[
              // 교정안 있는 경우 — 원문 / 교정본 비교
              _CorrectionCard(
                label: 'chat.correct_original'.tr(),
                text: original,
                color: const Color(0xFFFFF3F3),
                borderColor: const Color(0xFFFFCDD2),
                textColor: const Color(0xFFB71C1C),
              ),
              const SizedBox(height: 10),
              _CorrectionCard(
                label: 'chat.correct_suggested'.tr(),
                text: corrected,
                color: const Color(0xFFF0F4FF),
                borderColor: AppTheme.primary.withValues(alpha: 0.3),
                textColor: AppTheme.primary,
              ),
              if (explanation.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  explanation,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  // 원문 전송
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _sendMessage();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: BorderSide(color: AppTheme.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text('chat.correct_send_original'.tr(),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 교정본 전송
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _controller.text = corrected;
                        _sendMessage();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text('chat.correct_send_corrected'.tr(),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
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

  /// 상대방의 마지막 읽음 시각을 서버에서 초기 로드
  Future<void> _fetchOtherReadStatus(String roomId, int myId) async {
    try {
      final res = await ApiClient.get(
        '/chat/rooms/$roomId/read-status',
        params: {'user_id': '$myId'},
      );
      final raw = res['other_last_read_at'] as String?;
      if (raw != null && mounted) {
        setState(() => _otherLastReadAt = DateTime.tryParse(raw)?.toLocal());
      }
    } catch (_) {}
  }

  /// 채팅방 읽음 처리
  Future<void> _markAsRead(String roomId, int myId) async {
    try {
      await ApiClient.post(
        '/chat/rooms/$roomId/read',
        {'user_id': myId},
      );
    } catch (_) {}
  }

  /// 세션 타이머 시작
  void _startSessionTimer(String teach, String learn, int minutes) {
    _sessionTimer?.cancel();
    setState(() {
      _sessionTeach = teach;
      _sessionLearn = learn;
      _sessionTotalSeconds = minutes * 60;
      _sessionRemainingSeconds = minutes * 60;
      _sessionDone = false;
    });
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _sessionRemainingSeconds--);
      if (_sessionRemainingSeconds <= 0) {
        t.cancel();
        _onSessionComplete(autoFinished: true);
      }
    });
  }

  /// 세션 진행된 분 계산 (최소 1분)
  int get _elapsedMinutes {
    final elapsed = _sessionTotalSeconds - _sessionRemainingSeconds;
    return (elapsed / 60).ceil().clamp(1, 9999);
  }

  /// 세션 기록 저장 — teach/learn 비어 있거나 진행 시간 0이면 스킵
  Future<void> _saveSessionRecord() async {
    if (_sessionTeach.isEmpty || _sessionLearn.isEmpty) return;
    if (_sessionTotalSeconds <= 0) return;
    final myUser = _myUser;
    if (myUser == null) return;
    await SessionHistoryService.save(
      userId: int.tryParse(myUser.id) ?? 0,
      teach: _sessionTeach,
      learn: _sessionLearn,
      minutes: _elapsedMinutes,
      partnerName: widget.user.name,
      partnerId: int.tryParse(widget.user.id),
    );
  }

  /// 세션 타이머 수동 종료
  /// [notify] = true이면 상대방에게 __SESSION_STOP__ 전송 (기본값)
  void _stopSessionTimer({bool notify = true}) {
    _sessionTimer?.cancel();
    if (notify) _service?.send('__SESSION_STOP__');
    _saveSessionRecord(); // 기록 저장
    setState(() {
      _sessionRemainingSeconds = 0;
      _sessionDone = true;
    });
  }

  /// 세션 완료 처리
  void _onSessionComplete({bool autoFinished = false, bool notify = true}) {
    if (!mounted) return;
    _sessionTimer?.cancel();
    if (notify) _service?.send('__SESSION_STOP__');
    _saveSessionRecord(); // 기록 저장
    setState(() {
      _sessionRemainingSeconds = 0;
      _sessionDone = true;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 세션 완료!',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text(
          '$_sessionTeach ⇄ $_sessionLearn 세션이 끝났어요!\n수고하셨습니다.',
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sessionAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 세션 타이머 배너 (채팅 상단 고정)
  Widget _buildSessionBanner() {
    final total = math.max(_sessionRemainingSeconds, 0);
    final min = total ~/ 60;
    final sec = (total % 60).toString().padLeft(2, '0');

    return Container(
      color: AppTheme.session,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.swap_horiz_rounded,
              size: 16, color: AppTheme.sessionAccent),
          const SizedBox(width: 8),
          Text(
            '$_sessionTeach ⇄ $_sessionLearn',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.sessionAccent,
            ),
          ),
          const Spacer(),
          // 카운트다운
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.sessionAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined,
                    size: 13, color: AppTheme.sessionAccent),
                const SizedBox(width: 4),
                Text(
                  '$min:$sec',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.sessionAccent,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 완료 버튼
          GestureDetector(
            onTap: () {
              final teach = _sessionTeach;
              final learn = _sessionLearn;
              _stopSessionTimer(); // 내부에서 저장
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text('$teach ⇄ $learn 세션 완료!'),
                  ]),
                  backgroundColor: AppTheme.sessionAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.sessionAccent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'chat.session_done'.tr(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 언어교환 세션 시작 바텀시트
  void _showSessionSheet() {
    const languages = [
      '한국어', '영어', '중국어', '일본어', '베트남어',
      '프랑스어', '독일어', '스페인어', '러시아어', '아랍어',
    ];
    const durations = [15, 30, 45, 60];

    String teachLang = languages[0];
    String learnLang = languages[1];
    int minutes = 30;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final locale = context.locale.languageCode;
            final langLabel = languageLabelOf(locale);

            // ── 언어 선택 시트 ─────────────────────────────
            void pickLang(String current, void Function(String) onPick) {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (pickerCtx) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '언어 선택',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: languages.length,
                          itemBuilder: (_, i) {
                            final lang = languages[i];
                            final isSel = lang == current;
                            return InkWell(
                              onTap: () {
                                setSheet(() => onPick(lang));
                                Navigator.pop(pickerCtx);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 14),
                                child: Row(
                                  children: [
                                    Text(
                                      langLabel(lang),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSel
                                            ? FontWeight.w700
                                            : FontWeight.normal,
                                        color: isSel
                                            ? AppTheme.sessionAccent
                                            : AppTheme.textPrimary,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (isSel)
                                      const Icon(Icons.check_rounded,
                                          color: AppTheme.sessionAccent, size: 18),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(
                          height:
                              MediaQuery.of(pickerCtx).padding.bottom + 8),
                    ],
                  );
                },
              );
            }

            // ── 메인 시트 ─────────────────────────────────
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 핸들
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 타이틀
                  Row(
                    children: [
                      const Icon(Icons.swap_horiz_rounded,
                          size: 20, color: AppTheme.sessionAccent),
                      const SizedBox(width: 8),
                      Text(
                        'chat.session_title'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── 언어 선택 (두 박스 + ⇄) ─────────────
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 가르칠 언어 박스
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                pickLang(teachLang, (l) => teachLang = l),
                            child: Container(
                              padding:
                                  const EdgeInsets.fromLTRB(14, 12, 14, 14),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.session.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppTheme.session.withValues(alpha: 0.35),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'chat.session_teach'.tr(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.sessionAccent,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          langLabel(teachLang),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.expand_more_rounded,
                                          size: 18, color: AppTheme.sessionAccent),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ⇄ 화살표
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10),
                          child: Center(
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.session.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.swap_horiz_rounded,
                                  size: 20, color: AppTheme.sessionAccent),
                            ),
                          ),
                        ),

                        // 배울 언어 박스
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                pickLang(learnLang, (l) => learnLang = l),
                            child: Container(
                              padding:
                                  const EdgeInsets.fromLTRB(14, 12, 14, 14),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.session.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppTheme.session.withValues(alpha: 0.35),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'chat.session_learn'.tr(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.sessionAccent,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          langLabel(learnLang),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.expand_more_rounded,
                                          size: 18, color: AppTheme.sessionAccent),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  // 시간 선택
                  Text(
                    'chat.session_duration'.tr(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: durations.map((d) {
                      final sel = d == minutes;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setSheet(() => minutes = d),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 8),
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: sel ? AppTheme.sessionAccent : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: sel ? AppTheme.sessionAccent : AppTheme.border,
                              ),
                            ),
                            child: Text(
                              '${d}분',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: sel
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),
                  // 미리보기
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.session.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.session.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          langLabel(teachLang),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.sessionAccent,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.swap_horiz_rounded,
                              size: 16, color: AppTheme.sessionAccent),
                        ),
                        Text(
                          langLabel(learnLang),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.sessionAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.timer_outlined,
                            size: 13,
                            color: AppTheme.textSecondary
                                .withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Text(
                          '$minutes분',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  // 시작 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (teachLang == learnLang) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('chat.session_same_lang'.tr()),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.red.shade400,
                            ),
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                        final msg =
                            '__LANG_SESSION__|teach:$teachLang|learn:$learnLang|minutes:$minutes';
                        setState(() => _sessionDone = false);
                        _service?.send(msg);
                        _scrollToBottom();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.sessionAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'chat.session_start'.tr(),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 채팅방 나가기 확인 다이얼로그
  Future<void> _confirmLeave() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('채팅방 나가기'),
        content: const Text('채팅방을 나가면\n대화 내용이 모두 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              '나가기',
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) _leaveRoom();
  }

  /// 채팅방 삭제 후 이전 화면으로
  Future<void> _leaveRoom() async {
    try {
      final roomId = _resolvedRoomId ?? widget.roomId;
      final myId = int.tryParse(_service?.myUserId ?? '') ?? 0;
      if (roomId != null && myId > 0) {
        await ApiClient.delete(
          '/chat/rooms/$roomId',
          null,
          {'user_id': '$myId'},
        );
      }
    } catch (_) {}
    if (mounted) Navigator.pop(context);
  }

  void _showProfileSheet(BuildContext context) {
    final user = widget.user;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 드래그 핸들
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 아바타
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: avatarColorFor(user.name).withValues(alpha: 0.15),
              ),
              child: Center(
                child: Text(
                  avatarInitial(user.name),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: avatarColorFor(user.name),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 이름 + 국기
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (user.countryFlag.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(user.countryFlag,
                      style: const TextStyle(fontSize: 18)),
                ],
              ],
            ),
            const SizedBox(height: 4),
            // 국가명
            if (user.countryName.isNotEmpty)
              Text(
                user.countryName,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            const SizedBox(height: 4),
            // 전공 · 학년
            if (user.major.isNotEmpty)
              Text(
                [user.major, if (user.year.isNotEmpty) user.year].join(' · '),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            const SizedBox(height: 16),
            // 관심사 태그
            if (user.interests.isNotEmpty)
              Wrap(
                spacing: 7,
                runSpacing: 7,
                alignment: WrapAlignment.center,
                children: user.interests.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            // 언어 태그
            if (user.languages.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: user.languages.map((lang) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.translate_rounded,
                            size: 11, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          lang,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
            if (user.description.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                user.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  height: 1.6,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
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
        title: GestureDetector(
          onTap: () => _showProfileSheet(context),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: avatarColorFor(widget.user.name).withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Text(
                    avatarInitial(widget.user.name),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: avatarColorFor(widget.user.name),
                    ),
                  ),
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
                      if (widget.user.countryFlag.isNotEmpty) ...[
                        const SizedBox(width: 5),
                        Text(
                          widget.user.countryFlag,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                  _ConnectionLabel(state: _connState),
                ],
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                color: AppTheme.textPrimary, size: 22),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            color: Colors.white,
            elevation: 6,
            shadowColor: Colors.black.withValues(alpha: 0.10),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'session',
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppTheme.session.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.swap_horiz_rounded,
                          size: 17, color: AppTheme.sessionAccent),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'chat.session_title'.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              PopupMenuItem(
                value: 'leave',
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(Icons.exit_to_app_rounded,
                          size: 17, color: Colors.red.shade400),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '채팅방 나가기',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'session') _showSessionSheet();
              if (value == 'leave') _confirmLeave();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: Column(
        children: [
          // 언어교환 세션 타이머 배너
          if (_sessionActive) _buildSessionBanner(),
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
                        itemBuilder: (context, i) {
                          final msg = _messages[i];
                          final isRead = msg.isMe &&
                              _otherLastReadAt != null &&
                              !msg.timestamp.isAfter(_otherLastReadAt!);
                          return ChatBubble(
                            message: msg,
                            isRead: isRead,
                            senderName: msg.isMe ? '' : widget.user.name,
                            isSessionActive: _sessionActive,
                            isSessionDone: _sessionDone,
                            onSessionStart: _sessionActive
                                ? null // 이미 세션 중이면 비활성화
                                : (teach, learn, min) {
                                    _startSessionTimer(teach, learn, min);
                                    // 상대방에게 세션 시작 알림 (상대도 자동으로 타이머 시작)
                                    _service?.send(
                                        '__SESSION_START__|teach:$teach|learn:$learn|minutes:$min');
                                  },
                          );
                        },
                      ),
          ),
          if (!_loadingHistory && _showSuggestions) _buildSuggestionChips(),
          // 교정 로딩 중 표시
          if (_correcting)
            LinearProgressIndicator(
              minHeight: 2,
              color: AppTheme.primary,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            ),
          ChatInputBar(
            controller: _controller,
            onSend: _sendMessage,
            onCorrect: _correcting ? null : _correctMessage,
          ),
        ],
      ),
    );
  }
}

/// 교정 결과 카드 (원문 / 교정본)
class _CorrectionCard extends StatelessWidget {
  final String label;
  final String text;
  final Color color;
  final Color borderColor;
  final Color textColor;

  const _CorrectionCard({
    required this.label,
    required this.text,
    required this.color,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
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
