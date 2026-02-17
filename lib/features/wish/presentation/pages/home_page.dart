import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 추가
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

  // 🔄 1. 홈 탭 (실시간 위시 리스트)
  Widget _buildHomeTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      // 🔥 Supabase 실시간 스트림 연결: 'projects' 테이블의 변화를 감시합니다.
      stream: Supabase.instance.client
          .from('projects')
          .stream(primaryKey: ['id']) // id를 기준으로 변화를 추적
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("에러 발생: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("아직 등록된 위시가 없습니다."));
        }

        // 스트림으로 들어온 JSON 데이터를 ProjectModel 리스트로 변환
        final projects = snapshot.data!
            .map((json) => ProjectModel.fromJson(json))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            return ProjectCard(
              project: project,
              onTap: () async {
                // 상세 페이지 이동 (돌아올 때를 위해 await 사용 가능)
                await Navigator.push(
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

  // 2. 친구 탭
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
