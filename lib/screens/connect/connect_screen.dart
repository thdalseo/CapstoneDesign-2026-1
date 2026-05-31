import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../models/match_user.dart';
import '../../theme/app_theme.dart';
import '../matching/matching_screen.dart';
import '../chatting/chatting_screen.dart';

class ConnectScreen extends StatefulWidget {
  final List<MatchUser> users;
  final void Function(MatchUser) onToggle;
  final void Function(MatchUser) onStartChat;

  const ConnectScreen({
    super.key,
    required this.users,
    required this.onToggle,
    required this.onStartChat,
  });

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 상단 헤더 + 탭바
        Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text(
                  'nav.connect'.tr(),
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
                    fontSize: 14, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500),
                indicatorColor: AppTheme.primary,
                indicatorWeight: 2.5,
                tabs: [
                  Tab(text: 'nav.matching'.tr()),
                  Tab(text: 'nav.chat'.tr()),
                ],
              ),
            ],
          ),
        ),
        Container(height: 1, color: AppTheme.border),

        // 탭 콘텐츠
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              MatchingScreen(
                users: widget.users,
                onToggle: widget.onToggle,
                onStartChat: widget.onStartChat,
              ),
              const ChattingScreen(),
            ],
          ),
        ),
      ],
    );
  }
}
