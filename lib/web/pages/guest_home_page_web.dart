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
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHero(context)),
                SliverToBoxAdapter(child: _buildThreeSteps(context)),
                if (_tickerRows.isNotEmpty)
                  SliverToBoxAdapter(child: _buildTicker()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '지금 진행 중인 위시',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textHeading,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '다른 친구들은 어떤 선물을 받고 싶어할까요?',
                              style: GoogleFonts.notoSansKr(
                                fontSize: 14,
                                color: AppTheme.textBody,
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () => context.push('/explore'),
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                          ),
                          label: const Text('전체 보기'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
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
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                      child: _buildExampleWishList(context),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _crossCount(context),
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        childAspectRatio: 1,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _GuestWishCard(
                          project: _projects[i],
                          onTap: () =>
                              context.push('/project/${_projects[i].id}'),
                        ),
                        childCount: _projects.length,
                      ),
                    ),
                  ),
                SliverToBoxAdapter(child: _buildCtaBanner(context)),
                SliverToBoxAdapter(child: _buildFooter(context)),
              ],
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

  /// 위시리스트 예시 카드만 표시 (로그인 CTA 카드 제거)
  Widget _buildExampleWishList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossCount = constraints.maxWidth > 900
                ? 3
                : (constraints.maxWidth > 600 ? 2 : 1);
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossCount,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 1,
              children: [
                _ExampleWishCard(
                  title: 'iPad Pro 11형 (M4)',
                  description: '디자인 작업을 위해 꼭 필요해요!',
                  progress: 0.8,
                  dDay: 7,
                  currentAmount: 820000,
                  targetAmount: 1025000,
                  onSupportTap: _onCreateWishTap,
                ),
                _ExampleWishCard(
                  title: 'AirPods Max',
                  description: '소음 없는 나만의 시간이 필요해.',
                  progress: 0.45,
                  dDay: 14,
                  currentAmount: 346050,
                  targetAmount: 769000,
                  onSupportTap: _onCreateWishTap,
                ),
                _ExampleWishCard(
                  title: 'Sony A7 IV',
                  description: '꿈에 그리던 카메라!',
                  progress: 0.12,
                  dDay: 30,
                  currentAmount: 370800,
                  targetAmount: 3090000,
                  onSupportTap: _onCreateWishTap,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// 랜딩 스타일 히어로: 마음을 모아 더 큰 설렘으로 (단일 열)
  Widget _buildHero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 56),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.celebration_rounded,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '쉬워지는 소셜 기프팅',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '마음을 모아 더 큰\n설렘으로,',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: AppTheme.textHeading,
                ),
              ),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppTheme.primary, Color(0xFF818CF8)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(bounds),
                child: Text(
                  '함께 만드는 선물 위시드롭',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '원하는 선물을 친구들과 함께 펀딩해보세요.\n조금씩 모인 마음이 특별한 순간을 만듭니다.',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(
                  fontSize: 16,
                  height: 1.6,
                  color: AppTheme.textBody,
                ),
              ),
              const SizedBox(height: 32),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _onCreateWishTap,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('나의 위시 만들기'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/explore'),
                    icon: const Icon(Icons.explore_rounded, size: 20),
                    label: const Text('탐색에서 구경하기'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textHeading,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 세상에서 가장 쉬운 위시 펀딩 3단계
  Widget _buildThreeSteps(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Text(
                '세상에서 가장 쉬운 위시 펀딩',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textHeading,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '친구들과 선물을 주고받는 것이 더 쉬워집니다. 단 세 단계로 원하는 선물을 받아보세요.',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(
                  fontSize: 15,
                  color: AppTheme.textBody,
                ),
              ),
              const SizedBox(height: 40),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 700) {
                    return Column(
                      children: [
                        _stepCard(
                          Icons.edit_note_rounded,
                          '1. 위시 생성',
                          '받고 싶은 선물을 선택하세요.',
                        ),
                        const SizedBox(height: 16),
                        _stepCard(
                          Icons.group_add_rounded,
                          '2. 친구 초대',
                          '링크를 공유하고 마음을 모으세요.',
                        ),
                        const SizedBox(height: 16),
                        _stepCard(
                          Icons.card_giftcard_rounded,
                          '3. 선물 받기',
                          '목표가 달성되면 선물이 배달됩니다.',
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: _stepCard(
                          Icons.edit_note_rounded,
                          '1. 위시 생성',
                          '받고 싶은 선물을 선택하세요.',
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _stepCard(
                          Icons.group_add_rounded,
                          '2. 친구 초대',
                          '링크를 공유하고 마음을 모으세요.',
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _stepCard(
                          Icons.card_giftcard_rounded,
                          '3. 선물 받기',
                          '목표가 달성되면 선물이 배달됩니다.',
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, size: 28, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.notoSansKr(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textHeading,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansKr(
              fontSize: 14,
              color: AppTheme.textBody,
            ),
          ),
        ],
      ),
    );
  }

  /// 로고 + 탐색/로그인/회원가입
  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.card_giftcard,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '위시드롭',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textHeading,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => context.push('/explore'),
            child: Text(
              '탐색',
              style: GoogleFonts.notoSansKr(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textHeading,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.push('/login'),
            child: Text(
              '로그인',
              style: GoogleFonts.notoSansKr(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textHeading,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => context.push('/signup'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              '회원가입',
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// CTA 배너: 그라데이션 배경 + "설레는 위시, 지금 시작해보세요" + 아웃라인 버튼
  Widget _buildCtaBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1024),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 56),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF6366F1),
                  Color(0xFF4F46E5),
                  Color(0xFF4338CA),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '설레는 위시, 지금 시작해보세요',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '이미 수천 명의 사용자가 함께 선물을 주고받는 기쁨을 나누고 있습니다.\n더 의미 있고 즐거운 선물 문화를 경험해보세요.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 15,
                    height: 1.55,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 32),
                OutlinedButton(
                  onPressed: _onCreateWishTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    '첫 번째 위시 만들기',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 다크 푸터: 위시드롭 소개 + 서비스/회사/약관 열 + 저작권
  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 48),
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      decoration: const BoxDecoration(color: Color(0xFF1E293B)),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  if (!isWide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _footerBrand(context),
                        const SizedBox(height: 32),
                        _footerColumn('서비스', ['주요 기능', '이용 요금', '고객센터']),
                        const SizedBox(height: 24),
                        _footerColumn('회사 소개', ['위시드롭 이야기', '채용', '블로그']),
                        const SizedBox(height: 24),
                        _footerColumn('약관 및 정책', ['개인정보 처리방침', '이용약관', '보안']),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _footerBrand(context)),
                      Expanded(
                        child: _footerColumn('서비스', ['주요 기능', '이용 요금', '고객센터']),
                      ),
                      Expanded(
                        child: _footerColumn('회사 소개', [
                          '위시드롭 이야기',
                          '채용',
                          '블로그',
                        ]),
                      ),
                      Expanded(
                        child: _footerColumn('약관 및 정책', [
                          '개인정보 처리방침',
                          '이용약관',
                          '보안',
                        ]),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
              const Divider(color: Color(0xFF334155), height: 1),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '© 2024 Wish Drop Inc. All rights reserved.',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    '한국어 (대한민국)',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footerBrand(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.card_giftcard,
                size: 18,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '위시드롭',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '친구들과 함께 선물을 펀딩하는 가장 쉬운 방법. 마음을 모아 특별한 선물을 전하세요.',
          style: GoogleFonts.notoSansKr(
            fontSize: 14,
            color: const Color(0xFF94A3B8),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () {},
              color: const Color(0xFF94A3B8),
              style: IconButton.styleFrom(minimumSize: const Size(40, 40)),
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt_outlined),
              onPressed: () {},
              color: const Color(0xFF94A3B8),
              style: IconButton.styleFrom(minimumSize: const Size(40, 40)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _footerColumn(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.notoSansKr(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...links.map(
          (label) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () {},
              child: Text(
                label,
                style: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
        ),
      ],
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
        color: AppTheme.primary.withValues(alpha: 0.08),
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

/// 예시용 위시 카드 (실제 데이터 없이 표시) — 이미지 2배, 응원하기 버튼
class _ExampleWishCard extends StatelessWidget {
  final String title;
  final String description;
  final double progress;
  final int dDay;
  final int currentAmount;
  final int targetAmount;
  final VoidCallback? onSupportTap;

  const _ExampleWishCard({
    required this.title,
    required this.description,
    required this.progress,
    required this.dDay,
    required this.currentAmount,
    required this.targetAmount,
    this.onSupportTap,
  });

  @override
  Widget build(BuildContext context) {
    final dDayText = dDay >= 0 ? 'D-$dDay' : '종료';
    final percent = (progress * 100).toInt();
    final fmt = NumberFormat('#,###');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: Container(
                    color: const Color(0xFFF1F5F9),
                    child: Center(
                      child: Icon(
                        Icons.card_giftcard_rounded,
                        size: 80,
                        color: AppTheme.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
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
                      color: Colors.white.withValues(alpha: 0.95),
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textHeading,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13,
                    color: AppTheme.textBody,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1 ? Colors.green : AppTheme.primary,
                    ),
                    minHeight: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$percent% 달성!',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    Text(
                      '${fmt.format(currentAmount)} / ${fmt.format(targetAmount)}원',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 11,
                        color: AppTheme.textBody,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onSupportTap,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      foregroundColor: AppTheme.textHeading,
                    ),
                    child: Text(
                      '응원하기',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
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
                      color: Colors.white.withValues(alpha: 0.95),
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  project.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textHeading,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (project.description != null &&
                    project.description!.isNotEmpty)
                  Text(
                    project.description!,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      color: AppTheme.textBody,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1 ? Colors.green : AppTheme.primary,
                    ),
                    minHeight: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$percent% 달성! ${percent >= 50 ? '🔥' : ''}',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    Text(
                      '${fmt.format(project.currentAmount)} / ${fmt.format(project.targetAmount)}원',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 11,
                        color: AppTheme.textBody,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      foregroundColor: AppTheme.textHeading,
                    ),
                    child: Text(
                      '응원하기',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
