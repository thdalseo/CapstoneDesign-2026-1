import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../models/match_user.dart';
import '../../models/user_model.dart';
import '../../services/help_post_service.dart';
import '../../services/user_service.dart';
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

  // DB 저장값(한국어) 그대로 유지 - 필터링에 사용
  static const List<String> _categoryValues = [
    '전체', '생활', '수업', '언어', '의료', '캠퍼스', '행정', '기타',
  ];

  // 카테고리 표시 번역 키 매핑
  static const Map<String, String> _categoryKeys = {
    '전체': 'help.cat_all',
    '생활': 'help.cat_living',
    '수업': 'help.cat_class',
    '언어': 'help.cat_language',
    '의료': 'help.cat_medical',
    '캠퍼스': 'help.cat_campus',
    '행정': 'help.cat_admin',
    '기타': 'help.cat_other',
  };

  String _selectedCategory = '전체';
  bool _sortByUrgent = false;
  bool _sortBtnHovered = false;
  bool _fabHovered = false;
  int _displayCount = 10;
  bool _isLoading = false;

  UserModel? _currentUser;
  List<Map<String, dynamic>> _allPosts = [];
  List<Map<String, dynamic>> _myPosts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      setState(() => _displayCount = 10);
    });
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final user = await UserService.loadUser();
    if (mounted) setState(() => _currentUser = user);
    await _loadPosts();
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final allRaw = await HelpPostService.fetchPosts();
      final myRaw = _currentUser != null
          ? await HelpPostService.fetchMyPosts(_currentUser!.email)
          : <Map<String, dynamic>>[];

      if (mounted) {
        setState(() {
          _allPosts = allRaw.map((p) => _enrichPost(p)).toList();
          _myPosts = myRaw.map((p) => _enrichPost(p)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack(e is ApiException ? e.message : 'common.network_error'.tr());
      }
    }
  }

  Map<String, dynamic> _enrichPost(Map<String, dynamic> post) {
    final authorId = post['author_id']?.toString() ?? '';
    final isMyPost = _currentUser != null && authorId == _currentUser!.id;
    return {
      ...post,
      'isMyPost': isMyPost,
      'timeAgo': _timeAgo(post['createdAt'] as String?),
      'date': _formatDateDisplay(post['date'] as String?),
      'time': _formatTimeDisplay(post['time'] as String?),
      'rawDate': post['date'],
      'rawTime': post['time'],
    };
  }

  String _timeAgo(String? createdAt) {
    if (createdAt == null) return '';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return '방금 전';
      if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
      if (diff.inHours < 24) return '${diff.inHours}시간 전';
      return '${diff.inDays}일 전';
    } catch (_) {
      return '';
    }
  }

  String _formatDateDisplay(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;
    return '${parts[0]}년 ${int.tryParse(parts[1])}월 ${int.tryParse(parts[2])}일';
  }

  String _formatTimeDisplay(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    final parts = timeStr.split(':');
    if (parts.length < 2) return timeStr;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$period $displayHour:${minute.toString().padLeft(2, '0')}';
  }

  List<Map<String, dynamic>> get _filteredPosts {
    List<Map<String, dynamic>> posts = List.from(
      _tabController.index == 0 ? _allPosts : _myPosts,
    );
    if (_selectedCategory != '전체') {
      posts = posts.where((p) => p['category'] == _selectedCategory).toList();
    }
    if (_sortByUrgent) {
      // 긴급순: 긴급 여부 → 날짜 최신순
      posts.sort((a, b) {
        final aU = a['isUrgent'] as bool? ?? false;
        final bU = b['isUrgent'] as bool? ?? false;
        if (aU != bU) return aU ? -1 : 1;
        final aDate = a['createdAt'] as String? ?? '';
        final bDate = b['createdAt'] as String? ?? '';
        return bDate.compareTo(aDate);
      });
    } else {
      // 최신순: 날짜 내림차순
      posts.sort((a, b) {
        final aDate = a['createdAt'] as String? ?? '';
        final bDate = b['createdAt'] as String? ?? '';
        return bDate.compareTo(aDate);
      });
    }
    return posts;
  }

  Future<void> _openWritePost({Map<String, dynamic>? initialData}) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => WritePostScreen(initialData: initialData),
      ),
    );
    await _loadPosts();
  }

  void _deletePost(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('help.delete_title'.tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('help.delete_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await HelpPostService.deletePost(id);
                await _loadPosts();
              } catch (e) {
                _showSnack(e is ApiException
                    ? e.message
                    : 'common.network_error'.tr());
              }
            },
            child: Text('common.delete'.tr(),
                style: const TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  Future<void> _completePost(int id) async {
    try {
      await HelpPostService.completePost(id);
      await _loadPosts();
    } catch (e) {
      _showSnack(
          e is ApiException ? e.message : 'common.network_error'.tr());
    }
  }

  void _showHelpDialog(Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'help.dialog_title'
              .tr(namedArgs: {'name': post['authorName'] as String? ?? ''}),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Text('help.dialog_content'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr(),
                style: const TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (_currentUser != null) {
                try {
                  await HelpPostService.applyHelp(
                    post['id'] as int,
                    _currentUser!.email,
                  );
                  await _loadPosts();
                } on ApiException catch (e) {
                  if (e.statusCode != 409) {
                    _showSnack(e.message);
                    return;
                  }
                } catch (_) {}
              }

              final systemMessage = '🤝 함께해요!\n'
                  '📌 카테고리: ${post['category']}\n'
                  '📝 제목: ${post['title']}\n'
                  '📍 장소: ${post['place']}\n'
                  '📅 날짜: ${post['date']}\n'
                  '⏰ 시간: ${post['time']}\n\n'
                  '자유롭게 대화를 시작해보세요!';

              final user = MatchUser(
                id: post['author_id']?.toString() ?? '',
                name: post['authorName'] as String? ?? '',
                country: post['country'] as String? ?? '',
                major: post['major'] as String? ?? '',
                year: '',
                interests: [post['category'] as String? ?? ''],
                description: post['title'] as String? ?? '',
                matchPercent: 100,
              );

              widget.onStartChat(user, systemMessage);
            },
            child: Text('help.start_chat'.tr(),
                style: const TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text(
                  'help.title'.tr(),
                  style: const TextStyle(
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
                tabs: [
                  Tab(text: 'help.tab_all'.tr()),
                  Tab(text: 'help.tab_mine'.tr()),
                ],
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
            itemCount: _categoryValues.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = _categoryValues[i];
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
                    (_categoryKeys[cat] ?? cat).tr(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: selected ? Colors.white : AppTheme.textSecondary,
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
                'help.post_count'
                    .tr(namedArgs: {'count': '${filtered.length}'}),
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
                          _sortByUrgent
                              ? 'help.sort_urgent'.tr()
                              : 'help.sort_recent'.tr(),
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
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (displayed.isEmpty)
                _buildEmpty()
              else
                ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 88),
                  itemCount: displayed.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == displayed.length) {
                      return _buildLoadMore(filtered.length - _displayCount);
                    }
                    final post = displayed[i];
                    final isMyPost = post['isMyPost'] as bool? ?? false;
                    return HelpCard(
                      post: post,
                      onEdit: isMyPost
                          ? () => _openWritePost(initialData: post)
                          : null,
                      onDelete: isMyPost
                          ? () => _deletePost(post['id'] as int)
                          : null,
                      onComplete: isMyPost
                          ? () => _completePost(post['id'] as int)
                          : null,
                      onHelp: !isMyPost ? () => _showHelpDialog(post) : null,
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
                            color: AppTheme.primary.withValues(
                                alpha: _fabHovered ? 0.45 : 0.25),
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.transparent,
          overlayColor: AppTheme.textSecondary,
        ),
        child: Text(
          'help.load_more'
              .tr(namedArgs: {'remaining': '$remaining'}),
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
          Text(
            'help.empty_title'.tr(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'help.empty_desc'.tr(),
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
