import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme.dart';
import '../../../donation/data/donation_repository.dart';
import '../../data/project_model.dart';
import '../../data/project_repository.dart';
import '../widgets/project_card.dart';
import 'project_detail_page.dart';
import '../../../auth/presentation/pages/login_page.dart';

/// 비로그인 구경하기 홈 — 티커 + 위시 피드 + FAB "내 위시 만들기" (로그인 트리거)
class GuestHomePage extends StatefulWidget {
  const GuestHomePage({super.key});

  @override
  State<GuestHomePage> createState() => _GuestHomePageState();
}

class _GuestHomePageState extends State<GuestHomePage> {
  final _projectRepo = ProjectRepository();
  final _donationRepo = DonationRepository();
  List<ProjectModel> _projects = [];
  List<Map<String, dynamic>> _tickerRows = [];
  bool _loading = true;

  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _load();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri == null || !mounted) return;
      if (uri.host == 'project') {
        final idStr = uri.pathSegments.isNotEmpty
            ? uri.pathSegments.first
            : null;
        final projectId = idStr != null ? int.tryParse(idStr) : null;
        if (projectId != null) {
          final project = await _projectRepo.fetchProjectById(projectId);
          if (project != null && mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProjectDetailPage(project: project),
              ),
            );
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final active = await _projectRepo.fetchActiveProjects();
      if (mounted) {
        setState(() {
          _projects = active;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _projects = [];
          _loading = false;
        });
      }
    }
    _loadTicker();
  }

  Future<void> _loadTicker() async {
    try {
      final rows = await _donationRepo.getRecentDonationsForTicker(limit: 15);
      if (mounted) setState(() => _tickerRows = rows);
    } catch (_) {}
  }

  void _onCreateWishTap() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).padding.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Icon(
                Icons.card_giftcard,
                size: 48,
                color: AppTheme.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                '받고 싶은 선물이 있나요?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textHeading,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '로그인하고 내 위시를 등록해 보세요!',
                style: TextStyle(fontSize: 15, color: AppTheme.textBody),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      ctx,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '로그인하기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('위시드롭'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            child: const Text('로그인'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            if (_tickerRows.isNotEmpty)
              SliverToBoxAdapter(child: _buildTicker()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '지금 달성 중인 위시',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textHeading,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '친구들이 하나씩 마음을 모아가고 있어요. 구경해 보세요!',
                      style: TextStyle(fontSize: 14, color: AppTheme.textBody),
                    ),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_projects.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '아직 진행 중인 위시가 없어요',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textBody,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final project = _projects[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ProjectCard(
                        project: project,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProjectDetailPage(project: project),
                            ),
                          );
                        },
                      ),
                    );
                  }, childCount: _projects.length),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onCreateWishTap,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          '내 위시 만들기',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTicker() {
    if (_tickerRows.isEmpty) return const SizedBox.shrink();
    final messages = _tickerRows.map((r) {
      final a = r['donor_nickname'] as String? ?? '익명';
      final b = r['creator_nickname'] as String? ?? '누군가';
      final title = r['project_title'] as String? ?? '위시';
      final amount = (r['amount'] as num?)?.toInt() ?? 0;
      final fmt = NumberFormat('#,###');
      return '$a님이 $b님의 "$title" 위해 ${fmt.format(amount)}원을 보냈어요!';
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: _TickerStrip(messages: messages),
    );
  }
}

class _TickerStrip extends StatefulWidget {
  final List<String> messages;

  const _TickerStrip({required this.messages});

  @override
  State<_TickerStrip> createState() => _TickerStripState();
}

class _TickerStripState extends State<_TickerStrip> {
  final _scrollController = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScroll());
  }

  void _startScroll() {
    if (widget.messages.isEmpty) return;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      final current = _scrollController.offset;
      var next = current + 1.2;
      if (next >= max) next = 0;
      _scrollController.jumpTo(next);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) return const SizedBox.shrink();
    final duplicated = [...widget.messages, ...widget.messages];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      child: Row(
        children: [
          const SizedBox(width: 16),
          ...duplicated.map(
            (msg) => Padding(
              padding: const EdgeInsets.only(right: 48),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite, size: 16, color: Colors.red.shade400),
                  const SizedBox(width: 8),
                  Text(
                    msg,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textHeading,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}
