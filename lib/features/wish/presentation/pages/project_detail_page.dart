import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wish_drop/core/theme.dart';
import 'package:wish_drop/features/wish/data/project_model.dart';
import 'package:wish_drop/features/wish/data/project_repository.dart';
import 'package:wish_drop/features/wish/data/project_share_service.dart';
import 'package:wish_drop/features/donation/presentation/pages/donation_input_page.dart';

class ProjectDetailPage extends StatefulWidget {
  final ProjectModel project;
  const ProjectDetailPage({super.key, required this.project});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage>
    with SingleTickerProviderStateMixin {
  late ProjectModel _project;
  final _repo = ProjectRepository();
  bool _isChecking = true;
  late AnimationController _gaugeController;
  late Animation<double> _gaugeAnimation;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    final targetProgress = _project.progressRate.clamp(0.0, 1.0);
    _gaugeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _gaugeAnimation = Tween<double>(begin: 0, end: targetProgress).animate(
      CurvedAnimation(parent: _gaugeController, curve: Curves.easeOut),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _gaugeController.forward();
    });
    _checkAndRefresh();
  }

  @override
  void dispose() {
    _gaugeController.dispose();
    super.dispose();
  }

  Future<void> _checkAndRefresh() async {
    setState(() => _isChecking = true);
    try {
      await _repo.checkAndCompleteProjects();
      final updated = await _repo.fetchProjectById(_project.id);
      if (updated != null && mounted) setState(() => _project = updated);
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _deleteProject(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          "위시 삭제",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("정말로 이 위시리스트를 삭제하시겠습니까?\n삭제된 데이터는 복구할 수 없습니다."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("취소", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "삭제",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    Future<void> doDelete() => Supabase.instance.client
        .from('projects')
        .delete()
        .eq('id', _project.id);

    try {
      await doDelete();
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("위시리스트가 삭제되었습니다.")),
        );
      }
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      final isNetworkError = errStr.contains('connection') ||
          errStr.contains('abort') ||
          errStr.contains('socket');
      if (!isNetworkError) {
        if (context.mounted) {
          final msg = errStr.contains('foreign key')
              ? '후원 내역이 있어 삭제할 수 없습니다. (관리자: donations CASCADE 설정 필요)'
              : '삭제 실패: $e';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
        return;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("연결이 끊어졌을 수 있어요. 다시 시도합니다…")),
        );
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      if (!context.mounted) return;
      try {
        await doDelete();
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("위시리스트가 삭제되었습니다.")),
          );
        }
      } catch (e2) {
        if (context.mounted) {
          final msg = e2.toString().toLowerCase().contains('foreign key')
              ? '후원 내역이 있어 삭제할 수 없습니다. (관리자: donations CASCADE 설정 필요)'
              : '삭제 실패: $e2';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      }
    }
  }

  Future<void> _shareProject(BuildContext context) async {
    try {
      await ProjectShareService.shareProject(_project);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('공유 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,###");
    final currentUser = Supabase.instance.client.auth.currentUser;
    final bool isMyProject = _project.creatorId == currentUser?.id;
    final bool isCompleted = _project.isCompleted;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("선물 상세"),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _shareProject(context),
          ),
          if (isMyProject)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _deleteProject(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 150),
        child: Column(
          children: [
            // 종료 배너 (목표 달성 / 기간 만료)
            if (isCompleted) _CompletionBanner(project: _project),
            // 1. 이미지 영역
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child:
                      _project.thumbnailUrl != null &&
                          _project.thumbnailUrl!.isNotEmpty
                      ? Image.network(
                          _project.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey,
                              ),
                        )
                      : const Icon(Icons.image, size: 50, color: Colors.grey),
                ),
              ),
            ),

            // 2. 타이틀 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "🎁 위시 프로젝트",
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _project.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textHeading,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _project.description ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textBody,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            // 3. 원형 게이지 & 통계 (0% → 실제% 애니메이션)
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
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
                          painter: CircularGaugePainter(progress: animatedProgress),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "${(animatedProgress * 100).toInt()}%",
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textHeading,
                                  ),
                                ),
                                const Text(
                                  "달성 완료",
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
                      _statItem(
                        "현재 모금액",
                        "${currencyFormat.format(_project.currentAmount)}원",
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: AppTheme.borderColor,
                      ),
                      _statItem(
                        "목표 금액",
                        "${currencyFormat.format(_project.targetAmount)}원",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // 6. 하단 버튼 영역 (종료된 위시는 후원 버튼 숨김)
      bottomSheet: isCompleted
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                          builder: (context) =>
                              DonationInputPage(project: _project),
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
                            "한 조각 선물하기",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isMyProject) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => _deleteProject(context),
                      child: const Text(
                        "위시 삭제하기",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
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

// ── 종료 배너 (목표 달성 / 기간 만료) ─────────────────────────────

class _CompletionBanner extends StatelessWidget {
  final ProjectModel project;
  const _CompletionBanner({required this.project});

  @override
  Widget build(BuildContext context) {
    final byGoal = project.isCompletedByGoal;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      color: byGoal ? Colors.green.shade50 : Colors.orange.shade50,
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
}

// 🎨 원형 게이지 Painter (동일)
class CircularGaugePainter extends CustomPainter {
  final double progress;
  CircularGaugePainter({required this.progress});

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
