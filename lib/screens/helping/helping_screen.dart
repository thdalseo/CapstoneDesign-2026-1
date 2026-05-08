import 'package:flutter/material.dart';
import '../../models/match_user.dart';
import '../../theme/app_theme.dart';
import '../../widgets/helping/help_card.dart';
import 'write_post_screen.dart';

class HelpingScreen extends StatefulWidget {
  final void Function(MatchUser user, String systemMessage) onStartChat;

  const HelpingScreen({super.key, required this.onStartChat});

  @override
  State<HelpingScreen> createState() => _HelpingScreenState();
}

class _HelpingScreenState extends State<HelpingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _selectedCategory = '전체';
  bool _sortByUrgent = false;
  bool _sortBtnHovered = false;
  bool _fabHovered = false;
  int _displayCount = 10;

  // TODO: 백엔드 API 연동
  // GET /api/help-posts       → 게시글 목록 (페이지네이션, 카테고리 필터)
  // GET /api/help-posts/mine  → 내 게시글 목록
  final List<Map<String, dynamic>> _posts = [
    {
      'id': 1,
      'category': '언어',
      'title': '한국어 과제 피드백 부탁드려요!',
      'authorName': '안나',
      'major': '경영학과',
      'timeAgo': '1시간 전',
      'place': '도서관 1층',
      'date': '2024년 6월 15일',
      'time': '오후 2:00',
      'memo': '한국어 글쓰기 교정/문법 확인이 필요해요.',
      'helperCount': 2,
      'isUrgent': false,
      'isCompleted': false,
      'isMyPost': false,
    },
    {
      'id': 2,
      'category': '수업',
      'title': '코딩 공부 같이해요!',
      'authorName': '홍길동',
      'major': '컴퓨터공학과',
      'timeAgo': '3시간 전',
      'place': '중앙도서관',
      'date': '2024년 6월 16일',
      'time': '오전 10:00',
      'memo': '시험 준비 같이 할 스터디 구해요.',
      'helperCount': 1,
      'isUrgent': true,
      'isCompleted': false,
      'isMyPost': true,
    },
  ];

  static const List<String> _categories = [
    '전체',
    '생활',
    '수업',
    '언어',
    '의료',
    '캠퍼스',
    '행정',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      setState(() => _displayCount = 10);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredPosts {
    List<Map<String, dynamic>> posts = _tabController.index == 0
        ? List.from(_posts)
        : _posts.where((p) => p['isMyPost'] == true).toList();

    if (_selectedCategory != '전체') {
      posts = posts.where((p) => p['category'] == _selectedCategory).toList();
    }

    if (_sortByUrgent) {
      posts.sort((a, b) {
        final aU = a['isUrgent'] as bool? ?? false;
        final bU = b['isUrgent'] as bool? ?? false;
        if (aU && !bU) return -1;
        if (!aU && bU) return 1;
        return 0;
      });
    }

    return posts;
  }

  Future<void> _openWritePost({Map<String, dynamic>? initialData}) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => WritePostScreen(initialData: initialData),
      ),
    );
    if (result == null) return;

    setState(() {
      if (initialData != null) {
        final idx = _posts.indexWhere((p) => p['id'] == result['id']);
        if (idx != -1) _posts[idx] = result;
      } else {
        _posts.insert(0, result);
      }
    });
  }

  void _deletePost(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('게시글 삭제',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('정말 삭제하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _posts.removeWhere((p) => p['id'] == id));
              // TODO: DELETE /api/help-posts/{id}
            },
            child: const Text('삭제',
                style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  void _completePost(int id) {
    setState(() {
      final idx = _posts.indexWhere((p) => p['id'] == id);
      if (idx != -1) {
        _posts[idx] = Map<String, dynamic>.from(_posts[idx])
          ..['isCompleted'] = true;
      }
    });
    // TODO: PATCH /api/help-posts/{id}/complete
  }

  void _showHelpDialog(Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '${post['authorName']}님의 도움 요청에\n응답할게요',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onPressed: () {
              Navigator.pop(ctx);

              final systemMessage = '🤝 함께해요!\n'
                  '📌 카테고리: ${post['category']}\n'
                  '📝 제목: ${post['title']}\n'
                  '📍 장소: ${post['place']}\n'
                  '📅 날짜: ${post['date']}\n'
                  '⏰ 시간: ${post['time']}\n\n'
                  '자유롭게 대화를 시작해보세요!';

              final user = MatchUser(
                name: post['authorName'] as String,
                country: '🤝',
                major: post['major'] as String? ?? '',
                year: '',
                interests: [post['category'] as String? ?? ''],
                description: post['title'] as String? ?? '',
                matchPercent: 100,
              );

              // TODO: POST /api/chats          → 채팅방 생성
              // TODO: POST /api/messages/system → 시스템 메시지 전송
              widget.onStartChat(user, systemMessage);
            },
            child: const Text('채팅 시작하기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPosts;
    final displayed = filtered.take(_displayCount).toList();
    final hasMore = filtered.length > _displayCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더 + 탭
        Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text(
                  '도움',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500),
                indicatorColor: AppTheme.primary,
                indicatorWeight: 2.5,
                tabs: const [Tab(text: '전체'), Tab(text: '내 게시글')],
              ),
            ],
          ),
        ),

        // 카테고리 필터
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final selected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedCategory = cat;
                  _displayCount = 10;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primary : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected ? AppTheme.primary : AppTheme.border,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: selected
                          ? Colors.white
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // 정렬 토글
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Text(
                '게시글 ${filtered.length}개',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
              const Spacer(),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _sortBtnHovered = true),
                onExit: (_) => setState(() => _sortBtnHovered = false),
                child: GestureDetector(
                  onTap: () => setState(() {
                    _sortByUrgent = !_sortByUrgent;
                    _displayCount = 10;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _sortBtnHovered
                          ? AppTheme.border.withValues(alpha: 0.5)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.swap_vert_rounded,
                          size: 14,
                          color: _sortByUrgent
                              ? const Color(0xFFEF4444)
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _sortByUrgent ? '긴급순' : '최신순',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _sortByUrgent
                                ? const Color(0xFFEF4444)
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 게시글 목록
        Expanded(
          child: Stack(
            children: [
              displayed.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding:
                          const EdgeInsets.only(top: 4, bottom: 88),
                      itemCount: displayed.length + (hasMore ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i == displayed.length) {
                          return _buildLoadMore(
                              filtered.length - _displayCount);
                        }
                        final post = displayed[i];
                        final isMyPost =
                            post['isMyPost'] as bool? ?? false;
                        return HelpCard(
                          post: post,
                          onEdit: isMyPost
                              ? () =>
                                  _openWritePost(initialData: post)
                              : null,
                          onDelete: isMyPost
                              ? () =>
                                  _deletePost(post['id'] as int)
                              : null,
                          onComplete: isMyPost
                              ? () =>
                                  _completePost(post['id'] as int)
                              : null,
                          onHelp: !isMyPost
                              ? () => _showHelpDialog(post)
                              : null,
                        );
                      },
                    ),

              // 글쓰기 FAB
              Positioned(
                bottom: 16,
                right: 16,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _fabHovered = true),
                  onExit: (_) => setState(() => _fabHovered = false),
                  child: GestureDetector(
                    onTap: () => _openWritePost(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary
                                .withValues(alpha: _fabHovered ? 0.45 : 0.25),
                            blurRadius: _fabHovered ? 14 : 6,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadMore(int remaining) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: OutlinedButton(
        onPressed: () => setState(() => _displayCount += 10),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 44),
          side: const BorderSide(color: AppTheme.border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.transparent,
          overlayColor: AppTheme.textSecondary,
        ),
        child: Text(
          '더보기 ($remaining개 남음)',
          style: const TextStyle(
              fontSize: 14, color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
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
            child: const Icon(Icons.handshake_outlined,
                color: AppTheme.primary, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            '게시글이 없어요',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '도움이 필요하다면 글을 작성해보세요!',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
