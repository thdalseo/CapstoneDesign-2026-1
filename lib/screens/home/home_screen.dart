import 'package:flutter/material.dart';
import '../../models/match_user.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../screens/matching/matching_screen.dart';
import '../../screens/chatting/chatting_screen.dart';
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
        return const Center(child: Text('도움'));
      case 4:
        return const Center(child: Text('마이'));
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
        MyProfileCard(user: _currentUser),
        const SizedBox(height: 14),

        // 카드 PageView — 남은 공간을 모두 채움
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
    );
  }
}
