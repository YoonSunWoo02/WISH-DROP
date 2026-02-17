// features/pages/my_donation_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../repositories/donation_repository.dart';
import '../data/donation_model.dart';
import '../../core/theme.dart'; // 테마 파일 위치에 맞게 수정

class MyDonationPage extends StatefulWidget {
  const MyDonationPage({super.key});

  @override
  State<MyDonationPage> createState() => _MyDonationPageState();
}

class _MyDonationPageState extends State<MyDonationPage> {
  // 1. 리포지토리(심부름꾼) 생성
  final _repository = DonationRepository();

  // 데이터 담을 변수
  List<DonationModel> _donations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 2. 데이터 불러오기 (UI는 로직을 몰라도 됨!)
  Future<void> _loadData() async {
    try {
      final data = await _repository.getMyDonations();
      setState(() {
        _donations = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // 에러 처리 (스낵바 등)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("내 후원 내역"),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _donations.isEmpty
          ? _buildEmptyState()
          : _buildDonationList(),
    );
  }

  // 텅 비었을 때 화면
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "아직 후원한 내역이 없어요.",
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }

  // 리스트 화면
  Widget _buildDonationList() {
    final currencyFormat = NumberFormat("#,###");
    final dateFormat = DateFormat("yyyy.MM.dd HH:mm");

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _donations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = _donations[index];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // 프로젝트 썸네일
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: item.projectThumbnail != null
                    ? Image.network(
                        item.projectThumbnail!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[100],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 16),

              // 내용
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.projectTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(item.createdAt),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    // 내가 쓴 응원 메시지가 있으면 보여주기
                    if (item.message.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "💌 \"${item.message}\"",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textBody,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),

              // 금액
              Text(
                "${currencyFormat.format(item.amount)}원",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
