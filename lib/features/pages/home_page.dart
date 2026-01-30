import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
// 👇 경로들이 사용자님 구조에 맞게 수정되었습니다.
import 'package:wish_drop/features/cubit/auth_cubit.dart';
import 'package:wish_drop/features/cubit/funding_cubit.dart';
import 'package:wish_drop/features/data/funding_repository.dart';
import 'package:wish_drop/features/data/project_model.dart';
import 'package:wish_drop/features/pages/project_detail_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FundingCubit(FundingRepository()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("진행 중인 펀딩"),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => context.read<AuthCubit>().logout(),
            ),
          ],
        ),
        body: BlocBuilder<FundingCubit, FundingState>(
          builder: (context, state) {
            if (state is FundingLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is FundingError) {
              return Center(child: Text(state.message));
            } else if (state is FundingLoaded) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.projects.length,
                itemBuilder: (context, index) {
                  return _FundingCard(project: state.projects[index]);
                },
              );
            }
            return const SizedBox();
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _FundingCard extends StatelessWidget {
  final ProjectModel project;
  const _FundingCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,###원");

    return GestureDetector(
      // 👈 클릭 감지 기능 추가!
      onTap: () {
        // 상세 페이지로 이동!
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectDetailPage(project: project),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 20),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                project.thumbnailUrl ?? 'https://via.placeholder.com/400x200',
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 150,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
              ),
            ),
            // ... (아래 내용은 기존과 동일합니다) ...
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: project.progress,
                    backgroundColor: Colors.grey[200],
                    color: Colors.deepPurple,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${(project.progress * 100).toInt()}% 달성",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      Text(
                        "${currencyFormat.format(project.currentAmount)} 모임",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Text(
                    "목표: ${currencyFormat.format(project.targetAmount)}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
