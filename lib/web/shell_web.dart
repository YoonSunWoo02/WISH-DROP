import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';

/// 웹 전용 레이아웃 — 좌측 네비게이션 레일 + 콘텐츠 영역
/// 앱의 BottomNavigationBar와 유사한 UX
class ShellWeb extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const ShellWeb({
    super.key,
    this.currentPath = '/',
    required this.child,
  });

  int get _selectedIndex {
    if (currentPath.startsWith('/friend')) return 1;
    if (currentPath.startsWith('/my-info')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  context.go('/');
                  break;
                case 1:
                  context.go('/friend');
                  break;
                case 2:
                  context.go('/my-info');
                  break;
              }
            },
            backgroundColor: Colors.white,
            selectedIconTheme: const IconThemeData(color: AppTheme.primary),
            unselectedIconTheme: IconThemeData(color: Colors.grey.shade600),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('홈'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('친구'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('내 정보'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Wish Drop',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.textHeading,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_box_outlined),
          onPressed: () => context.push('/create'),
        ),
      ],
    );
  }
}
