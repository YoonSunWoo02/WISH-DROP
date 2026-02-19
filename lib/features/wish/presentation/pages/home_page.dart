import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme.dart';
import '../../data/project_model.dart';
import '../../data/project_repository.dart';
import '../widgets/project_card.dart';
import 'create_wish_page.dart';
import 'project_detail_page.dart';
import '../../../../profile/presentation/pages/my_info_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final ProjectRepository _repository = ProjectRepository();

  @override
  void initState() {
    super.initState();
    // 홈 로드 시 종료 체크 (end_date 만료 일괄 처리)
    _repository.checkAndCompleteProjects();
  }

  // 1. 홈 탭 (실시간 반영, active만 노출)
  Widget _buildHomeTab() {
    return StreamBuilder<List<ProjectModel>>(
      stream: _repository.getProjectsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("에러가 발생했습니다: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("아직 등록된 위시가 없습니다."));
        }

        // 종료 체크 후 active만 노출
        final projects = snapshot.data!
            .where((p) => p.status == 'active')
            .toList();
        if (projects.isEmpty) {
          return const Center(child: Text("아직 등록된 위시가 없습니다."));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            return ProjectCard(
              project: project,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProjectDetailPage(project: project),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // 2. 친구 탭 (준비 중)
  Widget _buildFriendsTab() {
    return const Center(child: Text("친구들의 위시를 준비 중입니다."));
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeTab(),
      _buildFriendsTab(),
      const MyInfoPage(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _currentIndex == 0
          ? AppBar(
              title: const Text(
                "Wish Drop",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_box_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateWishPage(),
                      ),
                    );
                  },
                ),
              ],
            )
          : null,
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: '친구',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '내 정보',
          ),
        ],
      ),
    );
  }
}
