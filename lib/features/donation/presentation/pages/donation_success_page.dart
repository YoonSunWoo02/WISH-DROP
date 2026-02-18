import 'package:flutter/material.dart';
import 'package:wish_drop/core/theme.dart';
// 🚨 홈 화면으로 가기 위해 꼭 필요합니다!
import 'package:wish_drop/features/wish/presentation/pages/home_page.dart';

class DonationSuccessPage extends StatelessWidget {
  const DonationSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background, // 또는 Colors.white
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. 성공 아이콘 또는 이미지
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.primary,
                  size: 80,
                ),
              ),
              const SizedBox(height: 32),

              // 2. 성공 메시지
              const Text(
                "후원이 완료되었습니다!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textHeading,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "소중한 마음을 전해주셔서 감사합니다.\n위시 달성에 한 걸음 더 가까워졌어요.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textBody,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              // 3. 홈으로 돌아가기 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // 🚀 [핵심 수정] 홈 화면으로 이동하며 스택 초기화
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const HomePage()),
                      (route) => false, // 뒤로 가기 버튼 눌러도 성공 화면 안 나오게 함
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "홈으로 돌아가기",
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
}
