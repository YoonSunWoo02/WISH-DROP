import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme.dart';
import '../../../features/donation/data/donation_repository.dart';
import '../../../features/wish/data/project_model.dart';
import '../../../features/wish/data/project_repository.dart';
import '../../../features/wish/data/project_share_service.dart';

/// 웹 위시 상세 — 독립 풀스크린 + 새 디자인 (Shell 없음)
class ProjectDetailPageWeb extends StatefulWidget {
  final int projectId;

  const ProjectDetailPageWeb({super.key, required this.projectId});

  @override
  State<ProjectDetailPageWeb> createState() => _ProjectDetailPageWebState();
}

class _ProjectDetailPageWebState extends State<ProjectDetailPageWeb>
    with SingleTickerProviderStateMixin {
  final _repo = ProjectRepository();
  final _donationRepo = DonationRepository();
  ProjectModel? _project;
  Map<String, dynamic>? _creatorProfile;
  List<Map<String, dynamic>> _donations = [];
  bool _isLoading = true;
  late AnimationController _gaugeController;
  late Animation<double> _gaugeAnimation;

  @override
  void initState() {
    super.initState();
    _gaugeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _gaugeAnimation = const AlwaysStoppedAnimation(0.0);
    _loadProject();
  }

  @override
  void dispose() {
    _gaugeController.dispose();
    super.dispose();
  }

  Future<void> _loadProject() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final project = await _repo.fetchProjectById(widget.projectId);
    if (!mounted) return;
    if (project != null) {
      _project = project;
      final progress = project.progressRate.clamp(0.0, 1.0);
      _gaugeAnimation = Tween<double>(begin: 0, end: progress).animate(
        CurvedAnimation(parent: _gaugeController, curve: Curves.easeOut),
      );
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _gaugeController.forward();
      });
      final profileRes = await Supabase.instance.client
          .from('profiles')
          .select('nickname, avatar_url')
          .eq('id', project.creatorId)
          .maybeSingle();
      if (mounted) _creatorProfile = profileRes;
      final donations = await _donationRepo.getDonationsForProject(project.id);
      if (mounted) _donations = donations;
    }
    if (mounted) setState(() => _isLoading = false);
    _checkAndRefresh();
  }

  Future<void> _checkAndRefresh() async {
    if (_project == null) return;
    try {
      await _repo.checkAndCompleteProjects();
      final updated = await _repo.fetchProjectById(_project!.id);
      if (updated != null && mounted) setState(() => _project = updated);
    } catch (_) {}
  }

  Future<void> _shareProject() async {
    if (_project == null) return;
    try {
      final url = ProjectShareService.getProjectShareUrl(_project!.id);
      final text = '${_project!.title}\n${_project!.description ?? ''}\n\n$url';
      await Share.share(text, subject: '위시드롭: ${_project!.title}');
    } catch (_) {
      final url = ProjectShareService.getProjectShareUrl(_project!.id);
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('링크가 복사되었습니다.')));
      }
    }
  }

  void _showLoginForDonationSheet(BuildContext context, ProjectModel project) {
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
              Icon(Icons.verified_user, size: 48, color: AppTheme.primary),
              const SizedBox(height: 16),
              Text(
                '안전한 결제와 후원 내역 저장을 위해\n3초 만에 로그인해 주세요!',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textHeading,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '로그인 후 바로 후원 단계로 이동합니다.',
                style: GoogleFonts.notoSansKr(
                  fontSize: 14,
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
                    context.push('/login?redirect=/project/${project.id}');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '로그인하고 후원하기',
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

  static bool _isMeaningfulText(String? s) {
    if (s == null || s.isEmpty) return false;
    final t = s.trim();
    if (t.isEmpty) return false;
    return !RegExp(r'^[\s\-_=\*#]+$').hasMatch(t);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_project == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '해당 위시를 찾을 수 없어요.',
                style: GoogleFonts.notoSansKr(
                  color: Colors.grey.shade700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('홈으로'),
              ),
            ],
          ),
        ),
      );
    }

    final project = _project!;
    final fmt = NumberFormat('#,###');
    final isCompleted = project.isCompleted;
    final daysLeft = project.daysLeft ?? 0;
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: isWide
                      ? _buildWideLayout(project, fmt, daysLeft, isCompleted)
                      : _buildNarrowLayout(project, fmt, daysLeft, isCompleted),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => context.canPop() ? context.pop() : context.go('/'),
      ),
      title: GestureDetector(
        onTap: () => context.go('/'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.card_giftcard,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '위시드롭',
              style: GoogleFonts.notoSansKr(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textHeading,
              ),
            ),
          ],
        ),
      ),
      centerTitle: true,
      actions: [
        if (_project != null)
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareProject,
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildWideLayout(
    ProjectModel project,
    NumberFormat fmt,
    int daysLeft,
    bool isCompleted,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 7, child: _buildMainContent(project, fmt)),
        const SizedBox(width: 24),
        SizedBox(
          width: 280,
          child: _buildActionCard(project, fmt, daysLeft, isCompleted),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(
    ProjectModel project,
    NumberFormat fmt,
    int daysLeft,
    bool isCompleted,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMainContent(project, fmt),
        const SizedBox(height: 20),
        _buildActionCard(project, fmt, daysLeft, isCompleted),
      ],
    );
  }

  Widget _buildMainContent(ProjectModel project, NumberFormat fmt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImageCard(project),
        const SizedBox(height: 20),
        _buildInfoCard(project),
        if (_donations.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildParticipantsCard(fmt),
        ],
      ],
    );
  }

  Widget _buildImageCard(ProjectModel project) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: project.thumbnailUrl != null && project.thumbnailUrl!.isNotEmpty
            ? Image.network(
                project.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imgPlaceholder(),
              )
            : _imgPlaceholder(),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
    color: Colors.grey.shade300,
    child: Icon(Icons.image_outlined, size: 64, color: Colors.grey.shade400),
  );

  Widget _buildInfoCard(ProjectModel project) {
    final nickname = _creatorProfile?['nickname'] as String? ?? '사용자';
    final avatarUrl = _creatorProfile?['avatar_url'] as String?;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Text(
                        nickname.isNotEmpty
                            ? nickname.substring(0, 1).toUpperCase()
                            : '?',
                        style: GoogleFonts.notoSansKr(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '받는 사람',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    nickname,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textHeading,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            project.title,
            style: GoogleFonts.notoSansKr(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textHeading,
              height: 1.4,
            ),
          ),
          if (_isMeaningfulText(project.welcomeMessage)) ...[
            const SizedBox(height: 12),
            Text(
              project.welcomeMessage!,
              style: GoogleFonts.notoSansKr(
                fontSize: 15,
                height: 1.6,
                color: Colors.grey.shade700,
              ),
            ),
          ],
          if (_isMeaningfulText(project.description)) ...[
            const SizedBox(height: 16),
            Text(
              project.description!,
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                height: 1.7,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionCard(
    ProjectModel project,
    NumberFormat fmt,
    int daysLeft,
    bool isCompleted,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '마감까지 $daysLeft일',
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade600,
                ),
              ),
              Text(
                '${_donations.length}명 참여',
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 100,
              height: 100,
              child: CustomPaint(
                painter: _GaugePainter(
                  progress: _gaugeAnimation.value,
                  color: AppTheme.primary,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(_gaugeAnimation.value * 100).toInt()}%',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textHeading,
                        ),
                      ),
                      Text(
                        '달성중',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${fmt.format(project.currentAmount)}원 모임',
            style: GoogleFonts.notoSansKr(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textHeading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '목표 ${fmt.format(project.targetAmount)}원',
            style: GoogleFonts.notoSansKr(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          if (!isCompleted)
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  final user = Supabase.instance.client.auth.currentUser;
                  if (user != null) {
                    context.push('/donation', extra: project);
                  } else {
                    _showLoginForDonationSheet(context, project);
                  }
                },
                icon: const Icon(Icons.card_giftcard, size: 18),
                label: const Text('🎁 후원하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _shareProject,
              icon: const Icon(Icons.share, size: 18),
              label: const Text('공유하기'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '안심하고 선물하세요',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                _safetyRow(Icons.verified_user, '결제 대금을 안전하게 보호합니다.'),
                const SizedBox(height: 4),
                _safetyRow(Icons.replay, '펀딩 실패 시 100% 환불 가능합니다.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _safetyRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppTheme.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.notoSansKr(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsCard(NumberFormat fmt) {
    final list = _donations.take(5).toList();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '참여한 친구들',
            style: GoogleFonts.notoSansKr(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textHeading,
            ),
          ),
          const SizedBox(height: 16),
          ...list.map((d) => _participantItem(d, fmt)),
        ],
      ),
    );
  }

  Widget _participantItem(Map<String, dynamic> d, NumberFormat fmt) {
    final nickname = d['donor_nickname'] as String? ?? '익명';
    final avatarUrl = d['donor_avatar_url'] as String?;
    final message = d['message'] as String? ?? '';
    final amount = d['amount'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            backgroundImage:
                avatarUrl != null && avatarUrl.toString().isNotEmpty
                ? NetworkImage(avatarUrl.toString())
                : null,
            child: avatarUrl == null || avatarUrl.toString().isEmpty
                ? Text(
                    nickname.isNotEmpty
                        ? nickname.substring(0, 1).toUpperCase()
                        : '?',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${fmt.format(amount)}원 후원',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
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

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  _GaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 6.0;

    final trackPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius - strokeWidth / 2, trackPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
