import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wish_drop/features/data/funding_repository.dart';
import 'package:wish_drop/features/data/project_model.dart';

class ProjectDetailPage extends StatefulWidget {
  final ProjectModel project;

  const ProjectDetailPage({super.key, required this.project});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  late ProjectModel _project; // 화면 갱신을 위해 변수로 관리
  final FundingRepository _repository = FundingRepository();
  bool _isLoading = false; // 로딩 상태

  @override
  void initState() {
    super.initState();
    _project = widget.project;
  }

  // 💰 후원하기 버튼 눌렀을 때 실행되는 함수
  Future<void> _handleDonation() async {
    // 1. 확인 팝업 띄우기
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("🎁 선물 후원하기"),
        content: const Text("10,000원을 후원하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("취소"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text("후원하기"),
          ),
        ],
      ),
    );

    if (confirm != true) return; // 취소했으면 멈춤

    setState(() => _isLoading = true); // 로딩 시작

    try {
      // 2. 서버에 10,000원 추가 요청 (RPC 호출)
      await _repository.donate(_project.id, 10000);

      // 3. 성공하면 화면 갱신 (가짜로 수치 올려서 바로 보여주기)
      setState(() {
        _project = ProjectModel(
          id: _project.id,
          title: _project.title,
          description: _project.description,
          targetAmount: _project.targetAmount,
          currentAmount: _project.currentAmount + 10000, // ✨ 1만원 즉시 추가!
          endDate: _project.endDate,
          thumbnailUrl: _project.thumbnailUrl,
        );
        _isLoading = false;
      });

      // 4. 축하 메시지
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🎉 후원 성공! 친구에게 마음이 전달되었어요.")),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("에러 발생: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,###원");

    return Scaffold(
      appBar: AppBar(title: const Text("프로젝트 상세"), centerTitle: true),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleDonation, // 로딩 중엔 버튼 비활성화
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    "10,000원 후원하기",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              _project.thumbnailUrl ?? 'https://via.placeholder.com/400x300',
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _project.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        "${(_project.progress * 100).toInt()}% 달성",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        currencyFormat.format(_project.currentAmount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // ✨ 애니메이션 게이지 바
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    tween: Tween<double>(begin: 0, end: _project.progress),
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      backgroundColor: Colors.grey[200],
                      color: Colors.deepPurple,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "목표 금액: ${currencyFormat.format(_project.targetAmount)} 까지",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const Divider(height: 40),
                  const Text(
                    "프로젝트 소개",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _project.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
