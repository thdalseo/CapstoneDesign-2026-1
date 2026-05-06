import 'package:flutter/material.dart';
import '../../models/match_user.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home/match_card.dart';
import '../../widgets/home/home_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _currentPage = 0;
  late final PageController _pageController;

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
        return const Center(child: Text('매칭'));
      case 2:
        return const Center(child: Text('채팅'));
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
          padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '안녕하세요, 민서님! 👋',
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
        const SizedBox(height: 20),

        // Today's Bridge 레이블
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 0, 14),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "Today's Bridge",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),

        // 카드 PageView
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.52,
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
                    vertical: 10,
                  ),
                  child: MatchCard(user: user),
                ),
              );
            },
          ),
        ),

        // 페이지 인디케이터 (작은 원 3개)
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 22),
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
