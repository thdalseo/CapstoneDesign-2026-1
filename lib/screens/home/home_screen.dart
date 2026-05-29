import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/match_user.dart';
import '../../models/user_model.dart';
import '../../services/match_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../screens/matching/matching_screen.dart';
import '../../screens/chatting/chatting_screen.dart';
import '../../screens/mypage/mypage_screen.dart';
import '../../screens/mypage/edit_profile_screen.dart';
import '../../screens/helping/helping_screen.dart';
import '../../screens/chatting/chatting_room_screen.dart';
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
  int _currentPage = 0;   // PageView 내 현재 카드 인덱스
  int _groupIndex = 0;    // 5명 묶음 그룹 인덱스
  late final PageController _pageController;
  UserModel? _currentUser;
  final List<MatchUser> _matchedUsers = [];   // 매칭 목록 (퍼즐 버튼)
  List<MatchUser> _matchList = [];
  bool _loadingMatches = false;

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
  String get _matchedKey =>
      'matched_users_json_${_currentUser?.email ?? 'guest'}';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.68);
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await UserService.loadUser();
    if (mounted) {
      setState(() => _currentUser = user);
      // 매칭 목록은 프로필 완성 여부와 무관하게 복원 (로그인 유지용)
      await _loadMatchedUsers();
      if (user != null && user.isProfileComplete) {
        await _loadMatches(user.email);
      }
    }
  }

  /// SharedPreferences에서 매칭 유저 전체 데이터를 복원
  /// → _matchList 의존 없이 독립적으로 동작
  Future<void> _loadMatchedUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_matchedKey);
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
    } catch (_) {
      // 파싱 실패 시 무시
    }
  }

  /// 매칭 유저 전체 데이터를 JSON으로 저장
  Future<void> _saveMatchedUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _matchedKey,
      jsonEncode(_matchedUsers.map((u) => u.toJson()).toList()),
    );
  }

  Future<void> _loadMatches(String email) async {
    if (_loadingMatches) return;
    setState(() => _loadingMatches = true);
    try {
      final matches = await MatchService.fetchMatches(email);
      final withReasons = matches
          .map((m) => m.copyWith(matchReasons: _computeReasons(m)))
          .toList();
      if (mounted) setState(() => _matchList = withReasons);
    } catch (_) {
      // 서버 연결 실패 시 빈 목록 유지
    } finally {
      if (mounted) setState(() => _loadingMatches = false);
    }
  }

  /// 나와 매칭 상대를 비교해 이유 문구 목록을 생성
  List<String> _computeReasons(MatchUser other) {
    final me = _currentUser;
    if (me == null) return [];
    final reasons = <String>[];

    // 1. 공통 관심사
    final common =
        me.interests.where((i) => other.interests.contains(i)).toList();
    if (common.isNotEmpty) {
      reasons.add('${common.take(2).join(', ')} 관심사가 일치해요');
    }

    // 2. 같은 전공
    if (me.major.isNotEmpty && me.major == other.major) {
      reasons.add('같은 전공이에요 (${me.major})');
    }

    // 3. 교류 목적 / 언어 교류
    final otherIsKorean =
        other.country.contains('대한민국') || other.countryName == '대한민국';
    final myIsKorean = me.countryName == '대한민국';
    if (myIsKorean != otherIsKorean) {
      reasons.add('언어·문화 교류에 최적인 조합이에요');
    } else if (other.countryName.isNotEmpty &&
        other.countryName != me.countryName) {
      reasons.add('다양한 문화적 배경을 가지고 있어요');
    }

    // 4. 매칭도 수준
    if (other.matchPercent >= 85) {
      reasons.add('전반적으로 매우 잘 맞는 상대예요 ✨');
    } else if (other.matchPercent >= 70) {
      reasons.add('여러 면에서 잘 맞는 상대예요');
    }

    // 기본 문구 (이유가 없을 때)
    if (reasons.isEmpty) {
      reasons.add('새로운 인연이 될 수 있어요');
    }

    return reasons;
  }

  void _toggleMatched(MatchUser user) {
    setState(() {
      final idx = _matchedUsers.indexWhere((u) => u.id == user.id);
      if (idx == -1) {
        _matchedUsers.add(user);
      } else {
        _matchedUsers.removeAt(idx);
      }
    });
    _saveMatchedUsers();
  }

  /// 채팅 시작 — 채팅방으로 이동 (채팅 목록은 서버에서 자동 관리)
  void _startChat(MatchUser user, {String? initialMessage}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChattingRoomScreen(
          user: user,
          initialMessage: initialMessage,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: HomeBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
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
            ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(user: _currentUser),
                  ),
                );
                _loadUser();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'home.go_to_profile'.tr(),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return MatchingScreen(
          users: _matchedUsers,
          onToggle: _toggleMatched,
          onStartChat: (user) => _startChat(user),
        );
      case 2:
        return const ChattingScreen();
      case 3:
        return HelpingScreen(
          onStartChat: (user, systemMessage) =>
              _startChat(user, initialMessage: systemMessage),
        );
      case 4:
        return const MyPageScreen();
      default:
        return _buildHomeTab();
    }
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
                    'home.greeting'
                        .tr(namedArgs: {'name': _currentUser?.name ?? ''}),
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
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppTheme.textSecondary,
                  size: 24,
                ),
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
                  Icon(Icons.people_outline_rounded,
                      size: 52, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text(
                    'home.no_matches'.tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textSecondary,
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
                      isMatched: _matchedUsers.any((u) => u.id == user.id),
                      onMatchTap: () => _toggleMatched(user),
                    ),
                  ),
                );
              },
            ),
          ),

          // 페이지 인디케이터 + 다음 추천 버튼
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Column(
              children: [
                // 인디케이터 (현재 그룹 내 카드 위치)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
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
                ),

                // 다음 추천 보기 버튼 (5명 초과일 때만)
                if (_matchList.length > 5) ...[
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _groupIndex = (_groupIndex + 1) % _totalGroups;
                        _currentPage = 0;
                      });
                      _pageController.jumpToPage(0);
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(
                      _groupIndex < _totalGroups - 1
                          ? 'home.next_recommendations'.tr()
                          : 'home.back_to_top'.tr(),
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
