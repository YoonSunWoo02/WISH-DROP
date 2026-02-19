import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';

import '../../../../core/theme.dart';
import '../../data/project_model.dart';
import '../../data/project_repository.dart';
import '../widgets/project_card.dart';
import 'create_wish_page.dart';
import 'project_detail_page.dart';
import '../../../../profile/presentation/pages/my_info_page.dart';
import '../../../friend/presentation/friend_page.dart';
import '../../../friend/data/friend_repository.dart';
import '../../../friend/presentation/friend_invite_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final ProjectRepository _repository = ProjectRepository();
  final _appLinks = AppLinks();
  final _friendRepo = FriendRepository(supabase: Supabase.instance.client);
  int _friendRequestCount = 0;

  @override
  void initState() {
    super.initState();
    // 홈 로드 시 종료 체크 (end_date 만료 일괄 처리)
    _repository.checkAndCompleteProjects();
    _loadRequestCount();
    _initDeepLinks();
  }

  Future<void> _loadRequestCount() async {
    final count = await _friendRepo.fetchPendingRequestCount();
    if (!mounted) return;
    setState(() => _friendRequestCount = count);
  }

  Future<void> _initDeepLinks() async {
    _listenDeepLinks();
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null && initialUri.host == 'friend') {
        final token = initialUri.queryParameters['token'];
        if (token != null && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FriendInvitePage(token: token),
            ),
          );
        }
      }
    } catch (_) {}
  }

  void _listenDeepLinks() {
    _appLinks.uriLinkStream.listen((uri) {
      if (!mounted) return;
      if (uri.host == 'friend') {
        final token = uri.queryParameters['token'];
        if (token != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FriendInvitePage(token: token),
            ),
          );
        }
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeTab(),
      const FriendPage(),
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
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) {
            _loadRequestCount();
          }
        },
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _friendRequestCount > 0,
              label: Text('$_friendRequestCount'),
              child: const Icon(Icons.people_outline),
            ),
            activeIcon: Badge(
              isLabelVisible: _friendRequestCount > 0,
              label: Text('$_friendRequestCount'),
              child: const Icon(Icons.people),
            ),
            label: '친구',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '내 정보',
          ),
        ],
      ),
    );
  }
}
