import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home/match_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // 샘플 매칭 데이터
  final List<Map<String, dynamic>> _matchList = [
    {
      'name': 'Sofia',
      'country': '🇺🇸',
      'major': '경영학과',
      'year': '2학년',
      'interests': ['여행', '카페 탐방', '영화'],
      'description': '한국어 공부 중이에요!\n서로 함께 언어 교환해요 😊',
      'matchPercent': 92,
    },
    {
      'name': 'Liam',
      'country': '🇬🇧',
      'major': '컴퓨터공학과',
      'year': '3학년',
      'interests': ['게임', '음악', 'K-POP'],
      'description': '한국 문화에 관심이 많아요!\n같이 공부도 하고 싶어요 📚',
      'matchPercent': 87,
    },
    {
      'name': 'Amara',
      'country': '🇳🇬',
      'major': '국제학부',
      'year': '1학년',
      'interests': ['요리', '운동', '사진'],
      'description': '캠퍼스 생활 도움이 필요해요!\n친하게 지내고 싶어요 😄',
      'matchPercent': 81,
    },
  ];

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const Center(child: Text('매칭'));
      case 2:
        return const Center(child: Text('도움'));
      case 3:
        return const Center(child: Text('채팅'));
      case 4:
        return const Center(child: Text('마이'));
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // 상단 인사
          Row(
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
          const SizedBox(height: 20),

          // 매칭 카드 PageView
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _matchList.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      final match = _matchList[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: MatchCard(
                          name: match['name'],
                          country: match['country'],
                          major: match['major'],
                          year: match['year'],
                          interests: List<String>.from(match['interests']),
                          description: match['description'],
                          matchPercent: match['matchPercent'],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // 페이지 인디케이터
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _matchList.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentPage == index ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppTheme.primary
                            : const Color(0xFFD0DCEF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppTheme.primary,
      unselectedItemColor: const Color(0xFFAAAAAA),
      selectedFontSize: 11,
      unselectedFontSize: 11,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: '홈',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.extension_outlined),  // 퍼즐 아이콘
          activeIcon: Icon(Icons.extension),
          label: '매칭',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.volunteer_activism_outlined),
          activeIcon: Icon(Icons.volunteer_activism),
          label: '도움',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          activeIcon: Icon(Icons.chat_bubble),
          label: '채팅',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: '마이',
        ),
      ],
    );
  }
}