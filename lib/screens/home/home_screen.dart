import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';
import '../../models/app_notification.dart';
import '../../models/match_user.dart';
import '../../models/user_model.dart';
import '../../services/match_service.dart';
import '../../services/notification_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../screens/mypage/mypage_screen.dart';
import '../../screens/mypage/edit_profile_screen.dart';
import '../../screens/helping/helping_screen.dart';
import '../../screens/chatting/chatting_room_screen.dart';
import '../../screens/chatting/chatting_screen.dart';
import '../../screens/matching/matching_screen.dart';
import '../../screens/notifications/notification_screen.dart';
import '../../widgets/home/match_card.dart';
import '../../widgets/home/home_bottom_nav.dart';
import '../../widgets/home/my_profile_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _currentPage = 0; // PageView 내 현재 카드 인덱스
  int _groupIndex = 0; // 5명 묶음 그룹 인덱스
  late final PageController _pageController;
  UserModel? _currentUser;
  final List<MatchUser> _matchedUsers = []; // 매칭 목록 (퍼즐 버튼)
  List<MatchUser> _matchList = [];
  bool _loadingMatches = false;

  // 채팅 관련 상태
  int _unreadCount = 0; // 읽지 않은 메시지 수 (하단 탭 뱃지)
  Set<String> _chatUserIds = {}; // 채팅방이 있는 유저 ID 집합
  /// 채팅 탭 활성화 펄스 — 값이 증가할 때마다 ChattingScreen이 즉시 갱신
  final _chatRefreshPulse = ValueNotifier<int>(0);

  /// 현재 그룹에서 보여줄 5명
  List<MatchUser> get _visibleMatches {
    final start = _groupIndex * 5;
    if (start >= _matchList.length) return [];
    return _matchList.skip(start).take(5).toList();
  }

  /// 전체 그룹 수
  int get _totalGroups =>
      _matchList.isEmpty ? 0 : ((_matchList.length - 1) ~/ 5) + 1;

  // 이메일별로 분리해 다른 계정의 매칭 목록이 섞이지 않도록 함
  String _matchedKeyForEmail(String? email) {
    final normalized = (email ?? '').trim().toLowerCase();
    return 'matched_users_json_${normalized.isEmpty ? 'guest' : normalized}';
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.68);
    NotificationService.instance.load();
    _loadUser();
  }

  Future<void> _loadUser() async {
    // ── 1단계: 로컬 캐시에서 즉시 로드 (서버 대기 없음) ─────────────────────
    final localUser = await UserService.loadUser(syncFromServer: false);
    if (!mounted) return;
    setState(() => _currentUser = localUser);

    // ── 2단계: 이메일 확보 즉시 매칭 목록 복원 ───────────────────────────────
    await _loadMatchedUsers(email: localUser?.email);

    // ── 3단계: 서버 동기화 (백엔드가 느리게 켜져도 로컬 데이터는 이미 복원됨) ──
    final user = await UserService.loadUser(syncFromServer: true);
    if (!mounted) return;
    if (user != null) {
      setState(() => _currentUser = user);
      await _loadMatchedUsers(email: user.email);
      await _loadSelectedMatchesFromServer(user.email);
    }

    if (user != null && user.isProfileComplete) {
      await _loadMatches(user.email);
    }

    // ── 4단계: 채팅 데이터 백그라운드 로드 ──────────────────────────────────
    _loadChatData();
  }

  /// SharedPreferences에서 매칭 유저 전체 데이터를 복원
  Future<void> _loadMatchedUsers({String? email}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_matchedKeyForEmail(email));
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      if (mounted) {
        setState(() {
          _matchedUsers.clear();
          _matchedUsers.addAll(
            list.map((e) => MatchUser.fromJson(e as Map<String, dynamic>)),
          );
        });
      }
    } catch (_) {}
  }

  /// 매칭 유저 전체 데이터를 JSON으로 저장
  Future<void> _saveMatchedUsers({String? email}) async {
    final ownerEmail = email ?? _currentUser?.email ?? '';
    if (ownerEmail.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _matchedKeyForEmail(ownerEmail),
      jsonEncode(_matchedUsers.map((u) => u.toJson()).toList()),
    );
  }

  Future<void> _loadSelectedMatchesFromServer(String email) async {
    try {
      final selected = await MatchService.fetchSelectedMatches(email);
      final withReasons = selected
          .map((m) => m.copyWith(matchReasons: _computeReasons(m)))
          .toList();
      if (!mounted) return;
      setState(() {
        _matchedUsers
          ..clear()
          ..addAll(withReasons);
      });
      await _saveMatchedUsers(email: email);
    } catch (_) {
      // 서버 조회 실패 시 이미 복원된 로컬 캐시를 유지한다.
    }
  }

  Future<void> _loadMatches(String email) async {
    if (_loadingMatches) return;
    setState(() => _loadingMatches = true);
    try {
      final matches = await MatchService.fetchMatches(email);
      final withReasons = matches
          .map((m) => m.copyWith(matchReasons: _computeReasons(m)))
          .toList();
      final reconciledMatchedUsers = _reconcileMatchedUsers(withReasons);
      if (mounted) {
        setState(() {
          _matchList = withReasons;
          if (reconciledMatchedUsers != null) {
            _matchedUsers
              ..clear()
              ..addAll(reconciledMatchedUsers);
          }
        });
        if (reconciledMatchedUsers != null) {
          await _saveMatchedUsers(email: email);
        }
        if (withReasons.isNotEmpty) {
          await NotificationService.instance.addOncePerDay(
            key: 'new-matches:$email:${withReasons.length}',
            type: AppNotificationType.match,
            title: 'notifications.new_match_title'.tr(),
            body: 'notifications.new_match_body'.tr(),
          );
        }
      }
    } catch (_) {
      // 서버 연결 실패 시 빈 목록 유지
    } finally {
      if (mounted) setState(() => _loadingMatches = false);
    }
  }

  /// 채팅방 목록을 가져와 unread 수 및 채팅 중인 유저 ID 집합을 업데이트
  List<MatchUser>? _reconcileMatchedUsers(List<MatchUser> latestMatches) {
    if (_matchedUsers.isEmpty) return null;

    final latestById = {
      for (final user in latestMatches)
        if (user.id.isNotEmpty) user.id: user,
    };
    final next = <MatchUser>[];
    var changed = false;

    for (final saved in _matchedUsers) {
      final latest = latestById[saved.id];
      if (latest == null) {
        next.add(saved);
        continue;
      }
      next.add(latest);
      if (latest.name != saved.name ||
          latest.country != saved.country ||
          latest.major != saved.major ||
          latest.matchPercent != saved.matchPercent) {
        changed = true;
      }
    }

    if (next.length != _matchedUsers.length) changed = true;
    return changed ? next : null;
  }

  Future<void> _loadChatData() async {
    try {
      final user = await UserService.loadUser(syncFromServer: false);
      final myId = user?.id ?? '';
      if (myId.isEmpty) return;

      final list = await ApiClient.getList(
        '/chat/rooms',
        params: {'user_id': myId},
      );
      final rooms = list.cast<Map<String, dynamic>>();

      if (!mounted) return;
      setState(() {
        _unreadCount = rooms.fold(
          0,
          (sum, r) => sum + ((r['unread_count'] as num?)?.toInt() ?? 0),
        );
        _chatUserIds = rooms
            .map((r) => r['other_user_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();
      });
    } catch (_) {
      // 채팅 데이터 로드 실패 시 무시 (뱃지만 안 뜸)
    }
  }

  /// 나와 매칭 상대를 비교해 이유 문구 목록을 생성
  List<String> _computeReasons(MatchUser other) {
    final me = _currentUser;
    if (me == null) return [];
    final reasons = <String>[];

    final common = me.interests
        .where((i) => other.interests.contains(i))
        .toList();
    if (common.isNotEmpty) {
      reasons.add('${common.take(2).join(', ')} 관심사가 일치해요');
    }

    if (me.major.isNotEmpty && me.major == other.major) {
      reasons.add('같은 전공이에요 (${me.major})');
    }

    final otherIsKorean =
        other.country.contains('대한민국') || other.countryName == '대한민국';
    final myIsKorean = me.countryName == '대한민국';
    if (myIsKorean != otherIsKorean) {
      reasons.add('언어·문화 교류에 최적인 조합이에요');
    } else if (other.countryName.isNotEmpty &&
        other.countryName != me.countryName) {
      reasons.add('다양한 문화적 배경을 가지고 있어요');
    }

    if (other.matchPercent >= 85) {
      reasons.add('전반적으로 매우 잘 맞는 상대예요 ✨');
    } else if (other.matchPercent >= 70) {
      reasons.add('여러 면에서 잘 맞는 상대예요');
    }

    if (reasons.isEmpty) {
      reasons.add('새로운 인연이 될 수 있어요');
    }

    return reasons;
  }

  Future<void> _toggleMatched(MatchUser user) async {
    final ownerEmail = _currentUser?.email ?? '';
    if (ownerEmail.isEmpty) return;

    final previous = List<MatchUser>.from(_matchedUsers);
    final shouldAdd = !_matchedUsers.any((u) => u.id == user.id);

    setState(() {
      final idx = _matchedUsers.indexWhere((u) => u.id == user.id);
      if (idx == -1) {
        _matchedUsers.add(user);
      } else {
        _matchedUsers.removeAt(idx);
      }
    });

    try {
      if (shouldAdd) {
        await MatchService.selectMatch(ownerEmail, user);
      } else {
        await MatchService.unselectMatch(ownerEmail, user);
      }
      await _saveMatchedUsers(email: ownerEmail);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _matchedUsers
          ..clear()
          ..addAll(previous);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('매칭 저장에 실패했습니다.')));
    }
  }

  /// 채팅 시작
  void _startChat(MatchUser user, {String? initialMessage}) {
    final userId = int.tryParse(user.id);
    if (userId == null || userId <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid match user.')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChattingRoomScreen(user: user, initialMessage: initialMessage),
      ),
    ).then((_) {
      // 채팅방에서 돌아올 때 채팅 목록 즉시 갱신
      _chatRefreshPulse.value++;
      _loadChatData();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _chatRefreshPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── 오프라인 배너 ────────────────────────────────────────────────
            ValueListenableBuilder<bool>(
              valueListenable: ApiClient.isOffline,
              builder: (_, offline, __) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: offline ? 30 : 0,
                  color: const Color(0xFFEF4444),
                  child: offline
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.wifi_off_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                            SizedBox(width: 6),
                            Text(
                              '서버에 연결할 수 없어요',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                );
              },
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: HomeBottomNav(
        currentIndex: _currentIndex,
        unreadCount: _unreadCount,
        onTap: (i) {
          setState(() => _currentIndex = i);
          if (i == 2) {
            // 채팅 탭 활성화 → ChattingScreen 즉시 갱신 펄스
            _chatRefreshPulse.value++;
            _loadChatData();
          }
        },
      ),
    );
  }

  Widget _buildProfileIncompleteSection() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 36,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'home.profile_incomplete_title'.tr(),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'home.profile_incomplete_desc'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(user: _currentUser),
                  ),
                );
                _loadUser();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                side: const BorderSide(color: AppTheme.primary, width: 1.5),
              ),
              child: Text(
                'home.go_to_profile'.tr(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    // IndexedStack: 모든 탭 위젯이 항상 살아있음
    // → ChattingScreen의 폴링 타이머가 어느 탭에서도 끊기지 않음
    return IndexedStack(
      index: _currentIndex,
      children: [
        _buildHomeTab(),
        MatchingScreen(
          users: _matchedUsers,
          onToggle: _toggleMatched,
          onStartChat: (user) => _startChat(user),
          chatUserIds: _chatUserIds,
        ),
        ChattingScreen(
          onUnreadChanged: (count) {
            if (mounted) setState(() => _unreadCount = count);
          },
          refreshPulse: _chatRefreshPulse,
        ),
        HelpingScreen(
          onStartChat: (user, systemMessage) =>
              _startChat(user, initialMessage: systemMessage),
        ),
        const MyPageScreen(),
      ],
    );
  }

  Widget _buildHomeTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단 인사
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'home.greeting'.tr(
                      namedArgs: {'name': _currentUser?.name ?? ''},
                    ),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'home.subtitle'.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              ValueListenableBuilder<List<AppNotification>>(
                valueListenable: NotificationService.instance.notifications,
                builder: (_, notifications, __) {
                  final unread = notifications
                      .where((notification) => !notification.isRead)
                      .length;

                  return IconButton(
                    tooltip: 'notifications.title'.tr(),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationScreen(),
                        ),
                      );
                    },
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.notifications_outlined,
                          color: AppTheme.textSecondary,
                          size: 24,
                        ),
                        if (unread > 0)
                          Positioned(
                            right: -3,
                            top: -4,
                            child: Container(
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: const BoxDecoration(
                                color: AppTheme.coral,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                unread > 9 ? '9+' : '$unread',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 내 프로필 카드
        MyProfileCard(
          user: _currentUser,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditProfileScreen(user: _currentUser),
              ),
            );
            _loadUser();
          },
        ),
        const SizedBox(height: 14),

        // 프로필 미완성 배너 or 매칭 카드
        if (_currentUser != null && !_currentUser!.isProfileComplete) ...[
          Expanded(child: _buildProfileIncompleteSection()),
        ] else if (_loadingMatches) ...[
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 2.5,
              ),
            ),
          ),
        ] else if (_matchList.isEmpty) ...[
          Expanded(
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
                      Icons.people_outline_rounded,
                      color: AppTheme.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'home.no_matches'.tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'home.no_matches_desc'.tr(),
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
          ),
        ] else ...[
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _visibleMatches.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, index) {
                final user = _visibleMatches[index];
                final alreadyMatched = _matchedUsers.any(
                  (u) => u.id == user.id,
                );
                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double scale = 1.0;
                    if (_pageController.hasClients &&
                        _pageController.page != null) {
                      final diff = (_pageController.page! - index).abs();
                      scale = (1.0 - diff * 0.05).clamp(0.95, 1.0);
                    }
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: MatchCard(
                      user: user,
                      isMatched: alreadyMatched,
                      isInChat: _chatUserIds.contains(user.id),
                      onMatchTap: () => _toggleMatched(user),
                    ),
                  ),
                );
              },
            ),
          ),

          // 인디케이터 + 새로고침 버튼
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 새로고침 버튼 (5명 초과 그룹이 있을 때만)
                if (_matchList.length > 5) ...[
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _groupIndex = (_groupIndex + 1) % _totalGroups;
                        _currentPage = 0;
                      });
                      _pageController.jumpToPage(0);
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        size: 15,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
                // 페이지 인디케이터 점
                ...List.generate(
                  _visibleMatches.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 9 : 7,
                    height: _currentPage == index ? 9 : 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? AppTheme.primary
                          : const Color(0xFFD0DCEF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
