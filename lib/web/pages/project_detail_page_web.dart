import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme.dart';
import '../../../features/wish/data/project_model.dart';
import '../../../features/wish/data/project_repository.dart';
import '../../../features/wish/data/project_share_service.dart';
import '../../../features/donation/presentation/pages/donation_input_page.dart';

/// 웹 전용 위시 상세 페이지 — projectId로 로드 후 앱과 동일 UI
class ProjectDetailPageWeb extends StatefulWidget {
  final int projectId;

  const ProjectDetailPageWeb({super.key, required this.projectId});

  @override
  State<ProjectDetailPageWeb> createState() => _ProjectDetailPageWebState();
}

class _ProjectDetailPageWebState extends State<ProjectDetailPageWeb>
    with SingleTickerProviderStateMixin {
  final _repo = ProjectRepository();
  ProjectModel? _project;
  bool _isLoading = true;
  bool _isChecking = false;
  late AnimationController _gaugeController;
  late Animation<double> _gaugeAnimation;

  @override
  void initState() {
    super.initState();
    _gaugeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
    setState(() => _isLoading = true);
    final project = await _repo.fetchProjectById(widget.projectId);
    if (!mounted) return;
    if (project != null) {
      _project = project;
      final targetProgress = project.progressRate.clamp(0.0, 1.0);
      _gaugeAnimation = Tween<double>(begin: 0, end: targetProgress).animate(
        CurvedAnimation(parent: _gaugeController, curve: Curves.easeOut),
      );
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _gaugeController.forward();
      });
    }
    setState(() => _isLoading = false);
    _checkAndRefresh();
  }

  Future<void> _checkAndRefresh() async {
    if (_project == null) return;
    setState(() => _isChecking = true);
    try {
      await _repo.checkAndCompleteProjects();
      final updated = await _repo.fetchProjectById(_project!.id);
      if (updated != null && mounted) {
        setState(() => _project = updated);
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _shareProject() async {
    if (_project == null) return;
    try {
      final url = ProjectShareService.getProjectShareUrl(_project!.id);
      final text = '${_project!.title}\n${_project!.description ?? ''}\n\n$url';
      await Share.share(text, subject: '위시드롭: ${_project!.title}');
    } catch (_) {
      // 폴백: 클립보드 복사
      final url = ProjectShareService.getProjectShareUrl(_project!.id);
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크가 복사되었습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_project == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('해당 위시를 찾을 수 없어요.'),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('홈으로'),
            ),
          ],
        ),
      );
    }

    final project = _project!;
    final currencyFormat = NumberFormat('#,###');
    final bool isCompleted = project.isCompleted;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/'),
        ),
        title: const Text('선물 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareProject,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
            children: [
              if (isCompleted) _buildCompletionBanner(project),
              _buildImageSection(project),
              _buildTitleSection(project),
              _buildGaugeSection(project, currencyFormat),
              if (!isCompleted) ...[
                if (_isChecking)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 6),
                        Text(
                          '최신 상태 확인 중...',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DonationInputPage(project: project),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.volunteer_activism, size: 20),
                        SizedBox(width: 10),
                        Text(
                          '한 조각 선물하기',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildCompletionBanner(ProjectModel project) {
    final byGoal = project.isCompletedByGoal;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: byGoal ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(byGoal ? '🎉' : '⏰', style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  byGoal ? '목표 금액을 달성했어요!' : '펀딩 기간이 종료됐어요.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: byGoal ? Colors.green.shade800 : Colors.orange.shade800,
                  ),
                ),
                Text(
                  byGoal
                      ? '많은 친구들의 응원 덕분이에요 💛'
                      : '더 이상 후원을 받을 수 없어요.',
                  style: TextStyle(
                    fontSize: 12,
                    color: byGoal ? Colors.green.shade600 : Colors.orange.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(ProjectModel project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: 1,
          child: project.thumbnailUrl != null && project.thumbnailUrl!.isNotEmpty
              ? Image.network(
                  project.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                )
              : const Icon(Icons.image, size: 50, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildTitleSection(ProjectModel project) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '🎁 위시 프로젝트',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            project.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.textHeading,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            project.description ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textBody,
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeSection(ProjectModel project, NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _gaugeAnimation,
            builder: (context, child) {
              final animatedProgress = _gaugeAnimation.value;
              return SizedBox(
                width: 160,
                height: 160,
                child: CustomPaint(
                  painter: _CircularGaugePainter(progress: animatedProgress),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(animatedProgress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textHeading,
                          ),
                        ),
                        const Text(
                          '달성 완료',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          const Divider(height: 1),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('현재 모금액', '${currencyFormat.format(project.currentAmount)}원'),
              Container(width: 1, height: 30, color: AppTheme.borderColor),
              _statItem('목표 금액', '${currencyFormat.format(project.targetAmount)}원'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textHeading,
          ),
        ),
      ],
    );
  }
}

class _CircularGaugePainter extends CustomPainter {
  final double progress;

  _CircularGaugePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 14.0;

    final trackPaint = Paint()
      ..color = const Color(0xFFF0F0F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius - strokeWidth / 2, trackPaint);

    final progressPaint = Paint()
      ..color = AppTheme.primary
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
