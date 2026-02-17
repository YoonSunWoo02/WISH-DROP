import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 👈 Supabase 패키지 추가
import 'package:wish_drop/core/theme.dart';
import 'package:wish_drop/features/data/project_model.dart';
import 'package:wish_drop/features/pages/donation_input_page.dart';

class ProjectDetailPage extends StatelessWidget {
  final ProjectModel project;
  const ProjectDetailPage({super.key, required this.project});

  // 🗑️ 프로젝트 삭제 로직
  Future<void> _deleteProject(BuildContext context) async {
    // 1. 확인 팝업 띄우기
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

    // 2. 취소했으면 함수 종료
    if (confirmed != true) return;

    try {
      // 3. Supabase DB에서 삭제 요청
      await Supabase.instance.client
          .from('projects')
          .delete()
          .eq('id', project.id); // 현재 프로젝트 ID와 일치하는 행 삭제

      // 4. 성공 시 홈 화면으로 복귀
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("위시리스트가 삭제되었습니다.")));
      }
    } catch (e) {
      // 5. 에러 처리
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("삭제 실패: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,###");

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("선물 상세"),
        actions: [
          // 상단에도 삭제 버튼 배치 (선택 사항, 아이콘 형태)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            onPressed: () => _deleteProject(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 150), // 하단 패딩 늘림 (버튼 공간 확보)
        child: Column(
          children: [
            // 1. 이미지 영역
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderColor),
                    color: Colors.white,
                    image: DecorationImage(
                      image: NetworkImage(project.thumbnailUrl ?? ''),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),

            // 2. 타이틀 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Text(
                    "🎓 졸업 선물 프로젝트",
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    project.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textHeading,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    project.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textBody,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // 3. 원형 게이지 & 통계
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CustomPaint(
                      painter: CircularGaugePainter(progress: project.progress),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${(project.progress * 100).toInt()}%",
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textHeading,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "ACHIEVED",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(height: 1, color: AppTheme.borderColor),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem(
                        "현재 모금액",
                        "${currencyFormat.format(project.currentAmount)}원",
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppTheme.borderColor,
                      ),
                      _statItem(
                        "목표 금액",
                        "${currencyFormat.format(project.targetAmount)}원",
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 4. 메시지 박스
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "지민님의 메시지",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.textHeading,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "\"졸업하고 새로운 시작을 위해 꼭 필요한 아이패드예요! 응원해주시는 모든 분들 정말 감사합니다.\"",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textBody,
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // 6. 하단 버튼 영역
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.borderColor)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 선물하기 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DonationInputPage(project: project),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: AppTheme.primary.withOpacity(0.2),
                    elevation: 8,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.volunteer_activism, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "한 조각 선물하기",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 🗑️ 위시 삭제하기 버튼 (추가됨)
              TextButton.icon(
                onPressed: () => _deleteProject(context),
                icon: const Icon(
                  Icons.delete_forever,
                  size: 18,
                  color: Colors.redAccent,
                ),
                label: const Text(
                  "위시 삭제하기",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  backgroundColor: Colors.red.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textHeading,
          ),
        ),
      ],
    );
  }
}

// 🎨 원형 게이지 Painter (기존 동일)
class CircularGaugePainter extends CustomPainter {
  final double progress;
  CircularGaugePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 12.0;

    final trackPaint = Paint()
      ..color = AppTheme.borderColor
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
