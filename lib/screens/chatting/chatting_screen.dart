import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../models/match_user.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/chatting/chat_room_tile.dart';
import 'chatting_room_screen.dart';

class ChattingScreen extends StatefulWidget {
  /// 읽지 않은 메시지 총합이 변경될 때 호출 (하단 탭 뱃지용)
  final void Function(int totalUnread)? onUnreadChanged;

  /// 채팅 탭 활성화 펄스 — 값이 바뀔 때마다 즉시 목록 갱신
  final ValueNotifier<int>? refreshPulse;

  const ChattingScreen({super.key, this.onUnreadChanged, this.refreshPulse});

  @override
  State<ChattingScreen> createState() => _ChattingScreenState();
}

class _ChattingScreenState extends State<ChattingScreen>
    with WidgetsBindingObserver {
  List<_RoomInfo> _rooms = [];
  bool _loading = true;
  bool _hasError = false;
  Timer? _pollTimer;

  /// 폴링 간격: 3초
  static const _pollInterval = Duration(seconds: 3);

  int get _totalUnread =>
      _rooms.fold(0, (sum, r) => sum + r.unreadCount);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.refreshPulse?.addListener(_onRefreshPulse);
    _fetchRooms();
    _startPolling();
  }

  void _onRefreshPulse() => _fetchRoomsForced();

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (mounted) _fetchRoomsSilently();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱이 포그라운드로 돌아오면 즉시 갱신
    if (state == AppLifecycleState.resumed) {
      _fetchRoomsSilently();
      _startPolling(); // 타이머 리셋
    } else if (state == AppLifecycleState.paused) {
      _pollTimer?.cancel(); // 백그라운드에서 폴링 중단
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    widget.refreshPulse?.removeListener(_onRefreshPulse);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 펄스 트리거: 로딩 상태 무관하게 강제 갱신 (탭 활성화 / 채팅방 복귀 시)
  Future<void> _fetchRoomsForced() async {
    try {
      final user = await UserService.loadUser(syncFromServer: false);
      final myId = user?.id ?? '';
      if (myId.isEmpty) return;
      final list = await ApiClient.getList('/chat/rooms', params: {'user_id': myId});
      final rooms = _parseRooms(list.cast<Map<String, dynamic>>());
      if (mounted) {
        setState(() => _rooms = rooms);
        widget.onUnreadChanged?.call(_totalUnread);
      }
    } catch (_) {}
  }

  /// 폴링용: 로딩 스피너 없이 조용히 목록 갱신 (이미 로딩 중이면 스킵)
  Future<void> _fetchRoomsSilently() async {
    if (_loading) return;
    try {
      final user = await UserService.loadUser(syncFromServer: false);
      final myId = user?.id ?? '';
      if (myId.isEmpty) return;

      final list = await ApiClient.getList(
        '/chat/rooms',
        params: {'user_id': myId},
      );
      final rooms = _parseRooms(list.cast<Map<String, dynamic>>());
      if (mounted) {
        setState(() => _rooms = rooms);
        widget.onUnreadChanged?.call(_totalUnread);
      }
    } catch (_) {
      // 폴링 실패는 조용히 무시
    }
  }

  Future<void> _fetchRooms() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final user = await UserService.loadUser(syncFromServer: false);
      final myId = user?.id ?? '';
      if (myId.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final list = await ApiClient.getList(
        '/chat/rooms',
        params: {'user_id': myId},
      );

      final rooms = _parseRooms(list.cast<Map<String, dynamic>>());

      if (mounted) {
        setState(() {
          _rooms = rooms;
          _loading = false;
        });
        // 읽지 않은 수 부모에 알림
        widget.onUnreadChanged?.call(_totalUnread);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
    }
  }

  List<_RoomInfo> _parseRooms(List<Map<String, dynamic>> list) {
    return list.map((json) {
      return _RoomInfo(
        roomId: (json['room_id'] as num?)?.toInt() ?? 0,
        user: MatchUser(
          id: json['other_user_id'] as String? ?? '',
          name: json['other_user_name'] as String? ?? '',
          country: json['other_user_country'] as String? ?? '',
          major: json['other_user_major'] as String? ?? '',
          year: json['other_user_year'] as String? ?? '',
          interests: (json['other_user_interests'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [],
          languages: (json['other_user_languages'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [],
          description: json['other_user_description'] as String? ?? '',
          matchPercent: 0,
        ),
        lastMessage: json['last_message'] as String?,
        lastMessageTime: json['last_message_time'] as String?,
        unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  /// ISO 타임스탬프 → "오전 10:23" / "어제" / "5/20"
  String _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final local = dt.toLocal();
    final now = DateTime.now();

    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      final h = local.hour;
      final m = local.minute.toString().padLeft(2, '0');
      final ampm = h < 12 ? '오전' : '오후';
      final h12 = h % 12 == 0 ? 12 : h % 12;
      return '$ampm $h12:$m';
    }
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    if (local.year == yesterday.year &&
        local.month == yesterday.month &&
        local.day == yesterday.day) {
      return '어제';
    }
    return '${local.month}/${local.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Row(
            children: [
              Text(
                'chat.title'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (_totalUnread > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _totalUnread > 99 ? '99+' : '$_totalUnread',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              // 새로고침 버튼
              IconButton(
                icon: const Icon(Icons.refresh_rounded,
                    size: 20, color: AppTheme.textSecondary),
                onPressed: _fetchRooms,
                tooltip: '새로고침',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        if (_loading)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 2,
              ),
            ),
          )
        else if (_hasError)
          _buildError()
        else if (_rooms.isEmpty)
          _buildEmpty()
        else
          _buildList(context),
      ],
    );
  }

  Widget _buildList(BuildContext context) {
    return Expanded(
      child: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _fetchRooms,
        child: ListView.separated(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: _rooms.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            indent: 82,
            endIndent: 20,
            color: AppTheme.border,
          ),
          itemBuilder: (context, i) {
            final room = _rooms[i];
            return ChatRoomTile(
              user: room.user,
              lastMessage: room.lastMessage,
              lastMessageTime: _formatTime(room.lastMessageTime),
              unreadCount: room.unreadCount,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChattingRoomScreen(
                      user: room.user,
                      roomId: room.roomId,
                    ),
                  ),
                );
                // 채팅방에서 돌아왔을 때 목록 갱신
                _fetchRooms();
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE8F0FE),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppTheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'chat.empty_title'.tr(),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'chat.empty_desc'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppTheme.textSecondary, size: 40),
            const SizedBox(height: 12),
            Text(
              'chat.conn_error'.tr(),
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _fetchRooms,
              child: Text('다시 시도',
                  style: TextStyle(color: AppTheme.primary)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 내부 데이터 클래스 ────────────────────────────────────────────────────────

class _RoomInfo {
  final int roomId;
  final MatchUser user;
  final String? lastMessage;
  final String? lastMessageTime;
  final int unreadCount;

  const _RoomInfo({
    required this.roomId,
    required this.user,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });
}
