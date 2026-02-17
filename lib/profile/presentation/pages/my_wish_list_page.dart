import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
// wish 기능 폴더의 데이터와 위젯을 가져오기 위한 경로
import '../../../features/wish/data/project_repository.dart';
import '../../../features/wish/data/project_model.dart';
import '../../../features/wish/presentation/widgets/project_card.dart';

class MyWishListPage extends StatelessWidget {
  const MyWishListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 탭 개수 (진행 중, 완료)
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text("내 위시 기록"),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: "진행 중"),
              Tab(text: "종료됨"),
            ],
            indicatorColor: AppTheme.primary,
            labelColor: AppTheme.primary,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: FutureBuilder<List<ProjectModel>>(
          future: ProjectRepository().getMyWishes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text("데이터를 불러오는 중 오류가 발생했습니다."));
            }

            final allWishes = snapshot.data ?? [];

            // 🚀 현재 시간을 기준으로 필터링
            final now = DateTime.now();
            final activeWishes = allWishes
                .where((w) => w.endDate.isAfter(now))
                .toList();
            final completedWishes = allWishes
                .where((w) => w.endDate.isBefore(now))
                .toList();

            return TabBarView(
              children: [
                _buildWishList(activeWishes, "진행 중인 위시가 없어요."),
                _buildWishList(completedWishes, "종료된 위시가 없어요."),
              ],
            );
          },
        ),
      ),
    );
  }

  // 리스트 빌더 위젯 분리
  Widget _buildWishList(List<ProjectModel> wishes, String emptyMessage) {
    if (wishes.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: wishes.length,
      itemBuilder: (context, index) {
        return ProjectCard(
          project: wishes[index],
          onTap: () {
            // 상세 정보나 관리 페이지 연결
          },
        );
      },
    );
  }
}
