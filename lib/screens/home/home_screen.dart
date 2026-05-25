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
  int _currentPage = 0;
  late final PageController _pageController;
  UserModel? _currentUser;
  final List<MatchUser> _matchedUsers = [];   // 매칭 목록 (퍼즐 버튼)
  List<MatchUser> _matchList = [];
  bool _loadingMatches = false;

  static const _matchedKey = 'matched_user_ids';

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
      if (user != null && user.isProfileComplete) {
        await _loadMatches(user.email);  // 먼저 목록 로드
        await _loadMatchedUsers();       // 그 다음 매칭 상태 복원
      }
    }
  }

  /// SharedPreferences에서 매칭된 유저 ID 목록을 복원
  Future<void> _loadMatchedUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_matchedKey) ?? [];
    if (mounted && ids.isNotEmpty) {
      setState(() {
        _matchedUsers.clear();
        _matchedUsers.addAll(
          _matchList.where((u) => ids.contains(u.id)),
        );
      });
    }
  }

  /// 매칭된 유저 ID 목록을 SharedPreferences에 저장
  Future<void> _saveMatchedUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _matchedKey,
      _matchedUsers.map((u) => u.id).toList(),
    );
  }

  Future<void> _loadMatches(String email) async {
    if (_loadingMatches) return;
    setState(() => _loadingMatches = true);
    try {
      final matches = await MatchService.fetchMatches(email);
      if (mounted) setState(() => _matchList = matches);
    } catch (_) {
      // 서버 연결 실패 시 빈 목록 유지
    } finally {
      if (mounted) setState(() => _loadingMatches = false);
    }
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
              itemCount: _matchList.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, index) {
                final user = _matchList[index];
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
                      isMatched: _matchedUsers.any((u) => u.name == user.name),
                      onMatchTap: () => _toggleMatched(user),
                    ),
                  ),
                );
              },
            ),
          ),

          // 페이지 인디케이터
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _matchList.length,
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
          ),
        ],
      ],
    );
  }
}
