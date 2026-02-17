import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme.dart';
import '../../data/donation_repository.dart';

class MyDonationPage extends StatelessWidget {
  const MyDonationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = DonationRepository();
    final formatter = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("내 후원 내역"),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: repository.getMyDonations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(child: Text("아직 후원한 내역이 없습니다."));
          }

          final donations = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: donations.length,
            itemBuilder: (context, index) {
              final item = donations[index];
              final String projectTitle =
                  item['projects']?['title'] ?? '삭제된 프로젝트';
              final int amount = item['amount'] ?? 0;
              final DateTime date = DateTime.parse(
                item['created_at'],
              ).toLocal();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('yyyy.MM.dd HH:mm').format(date),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      projectTitle,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "후원 금액",
                          style: TextStyle(color: AppTheme.textBody),
                        ),
                        Text(
                          "${formatter.format(amount)}원",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
