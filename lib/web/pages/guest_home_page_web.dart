import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../features/donation/data/donation_repository.dart';
import '../../features/wish/data/project_model.dart';
import '../../features/wish/data/project_repository.dart';

/// 비로그인 구경하기 홈 — 티커 + 위시 피드 + 플로팅 "내 위시 만들기" (로그인 트리거)
class GuestHomePageWeb extends StatefulWidget {
  const GuestHomePageWeb({super.key});

  @override
  State<GuestHomePageWeb> createState() => _GuestHomePageWebState();
}

class _GuestHomePageWebState extends State<GuestHomePageWeb> {
  final _projectRepo = ProjectRepository();
  final _donationRepo = DonationRepository();
  List<ProjectModel> _projects = [];
  List<Map<String, dynamic>> _tickerRows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
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
              Icon(Icons.card_giftcard, size: 48, color: AppTheme.primary),
              const SizedBox(height: 16),
              Text(
                '받고 싶은 선물이 있나요?',
                style: GoogleFonts.notoSansKr(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textHeading,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '로그인하고 내 위시를 등록해 보세요!',
                style: GoogleFonts.notoSansKr(
                  fontSize: 15,
                  color: AppTheme.textBody,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '로그인하기',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
      body: CustomScrollView(
        slivers: [
          if (_tickerRows.isNotEmpty) SliverToBoxAdapter(child: _buildTicker()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '지금 달성 중인 위시',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textHeading,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '친구들이 하나씩 마음을 모아가고 있어요. 구경해 보세요!',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 14,
                      color: AppTheme.textBody,
                    ),
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
                    Text(
                      '아직 진행 중인 위시가 없어요',
                      style: GoogleFonts.notoSansKr(
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _crossCount(context),
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.68,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _GuestWishCard(
                    project: _projects[i],
                    onTap: () => context.push('/project/${_projects[i].id}'),
                  ),
                  childCount: _projects.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onCreateWishTap,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          '내 위시 만들기',
          style: GoogleFonts.notoSansKr(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  int _crossCount(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w > 900) return 3;
    if (w > 600) return 2;
    return 1;
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
                    style: GoogleFonts.notoSansKr(
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

class _GuestWishCard extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onTap;

  const _GuestWishCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final endDate = project.endDate ?? DateTime.now();
    final dDay = endDate.difference(DateTime.now()).inDays;
    final dDayText = dDay >= 0 ? 'D-$dDay' : '종료';
    final progress = project.progressRate;
    final percent = (progress * 100).toInt();
    final fmt = NumberFormat('#,###');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.06),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child:
                      project.thumbnailUrl != null &&
                          project.thumbnailUrl!.isNotEmpty
                      ? Image.network(
                          project.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: dDay <= 7
                            ? Colors.red.shade200
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      '마감 $dDayText',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: dDay <= 7
                            ? Colors.red.shade700
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textHeading,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 1 ? Colors.green : AppTheme.primary,
                      ),
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$percent% 달성! ${percent >= 50 ? '🔥' : ''}',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      Text(
                        '${fmt.format(project.currentAmount)} / ${fmt.format(project.targetAmount)}원',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 12,
                          color: AppTheme.textBody,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(Icons.card_giftcard, size: 56, color: AppTheme.primary),
      ),
    );
  }
}
