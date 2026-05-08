import 'package:flutter/material.dart';
import '../../models/match_user.dart';
import '../../models/user_model.dart';
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
  final List<MatchUser> _matchedUsers = [];

  final List<MatchUser> _matchList = const [
    MatchUser(
      name: 'Sofia',
      country: '🇺🇸',
      major: '경영학과',
      year: '2학년',
      interests: ['여행', '카페 탐방', '영화'],
      description: '한국어 공부 중이에요!\n서로 함께 언어 교환해요 😊',
      matchPercent: 92,
    ),
    MatchUser(
      name: 'Liam',
      country: '🇬🇧',
      major: '컴퓨터공학과',
      year: '3학년',
      interests: ['게임', '음악', 'K-POP'],
      description: '한국 문화에 관심이 많아요!\n같이 공부도 하고 싶어요 📚',
      matchPercent: 87,
    ),
    MatchUser(
      name: 'Amara',
      country: '🇳🇬',
      major: '국제학부',
      year: '1학년',
      interests: ['요리', '운동', '사진'],
      description: '캠퍼스 생활 도움이 필요해요!\n친하게 지내고 싶어요 😄',
      matchPercent: 81,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.68);
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await UserService.loadUser();
    if (mounted) setState(() => _currentUser = user);
  }

  void _toggleMatched(MatchUser user) {
    setState(() {
      final idx = _matchedUsers.indexWhere((u) => u.name == user.name);
      if (idx == -1) {
        _matchedUsers.add(user);
      } else {
        _matchedUsers.removeAt(idx);
      }
    });
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
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 36,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '프로필을 완성해주세요!',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '학년, 관심사, 교류 목적을 설정하면\n나와 잘 맞는 친구들을 만날 수 있어요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
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
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '프로필 설정하러 가기',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
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
        );
      case 2:
        return ChattingScreen(users: _matchedUsers);
      case 3:
        return HelpingScreen(
          onStartChat: (user, systemMessage) {
            if (!_matchedUsers.any((u) => u.name == user.name)) {
              setState(() => _matchedUsers.add(user));
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChattingRoomScreen(
                  user: user,
                  initialMessage: systemMessage,
                ),
              ),
            );
          },
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
                    '안녕하세요, ${_currentUser?.name ?? ''}님! 👋',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '당신과 잘 맞는 친구들을 소개할게요.',
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

          // 페이지 인디케이터 (작은 원 3개)
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
