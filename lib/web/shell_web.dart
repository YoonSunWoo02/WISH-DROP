import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme.dart';

/// 웹 대시보드 레이아웃 — 헤더 + 사이드바 + 콘텐츠
class ShellWeb extends StatefulWidget {
  final Widget child;
  final String currentPath;

  const ShellWeb({super.key, this.currentPath = '/', required this.child});

  @override
  State<ShellWeb> createState() => _ShellWebState();
}

class _ShellWebState extends State<ShellWeb> {
  String? _userNickname;
  String? _avatarUrl;

  int get _selectedIndex {
    if (widget.currentPath.startsWith('/friend')) return 2;
    if (widget.currentPath.startsWith('/settings')) return 3;
    if (widget.currentPath.startsWith('/my-info')) return 4;
    if (widget.currentPath.startsWith('/explore')) return 1;
    if (widget.currentPath.startsWith('/project/')) return -1;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final res = await Supabase.instance.client
        .from('profiles')
        .select('nickname, avatar_url')
        .eq('id', user.id)
        .maybeSingle();
    if (!mounted) return;
    setState(() {
      _userNickname = res?['nickname'] as String?;
      _avatarUrl = res?['avatar_url'] as String?;
    });
  }

  @override
  Widget build(BuildContext context) {
    final showSidebar = MediaQuery.of(context).size.width >= 1024;
    const sidebarWidth = 256.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showSidebar)
            SizedBox(width: sidebarWidth, child: _buildSidebar(context)),
          Expanded(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: showSidebar ? null : _buildBottomNavBar(context),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _bottomNavItem(
                context,
                index: 0,
                icon: Icons.home,
                label: '홈',
                route: '/',
              ),
              _bottomNavItem(
                context,
                index: 1,
                icon: Icons.explore,
                label: '탐색',
                route: '/explore',
              ),
              _bottomNavItem(
                context,
                index: 2,
                icon: Icons.group,
                label: '친구',
                route: '/friend',
              ),
              _bottomNavItem(
                context,
                index: 3,
                icon: Icons.settings,
                label: '설정',
                route: '/settings',
              ),
              _bottomNavItem(
                context,
                index: 4,
                icon: Icons.person,
                label: '마이페이지',
                route: '/my-info',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required String route,
  }) {
    final selected = _selectedIndex == index;
    final color = selected ? AppTheme.primary : AppTheme.textBody;
    return InkWell(
      onTap: () => GoRouter.of(context).go(route),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isMd = MediaQuery.of(context).size.width >= 768;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          _buildLogo(context),
          if (isMd) ...[
            const SizedBox(width: 24),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 512),
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          size: 20,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '친구, 위시 검색...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(width: 16),
          IconButton(
            onPressed: () {},
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: Colors.grey.shade600,
                  size: 24,
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildProfile(context),
        ],
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/'),
        child: SizedBox(
          height: 40,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '위시드롭',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textHeading,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfile(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/my-info'),
        child: Container(
          height: 48,
          padding: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                    ? NetworkImage(_avatarUrl!)
                    : null,
                child: _avatarUrl == null || _avatarUrl!.isEmpty
                    ? Text(
                        (_userNickname?.isNotEmpty == true
                                ? _userNickname!.substring(0, 1)
                                : '?')
                            .toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
              if (MediaQuery.of(context).size.width >= 768) ...[
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userNickname ?? '회원',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textHeading,
                      ),
                    ),
                    Text(
                      '#${Supabase.instance.client.auth.currentUser?.id.substring(0, 4) ?? '----'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(Icons.expand_more, size: 20, color: Colors.grey.shade500),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 256,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              children: [
                _navItem(context, 0, Icons.home_rounded, '홈'),
                _navItem(context, 2, Icons.group_rounded, '친구'),
                _navItem(context, 1, Icons.explore_rounded, '탐색'),
                _navItem(context, 4, Icons.person_rounded, '마이페이지'),
                _navItem(context, 3, Icons.settings_rounded, '설정'),
                const SizedBox(height: 32),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '내 위시리스트',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _navSubItem(context, '생일 선물'),
                _navSubItem(context, '졸업 선물'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/create'),
                icon: const Icon(Icons.add_rounded, size: 22),
                label: const Text('위시 만들기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: AppTheme.primary.withValues(alpha: 0.25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final isSelected = _selectedIndex == index;
    final route = index == 0
        ? '/'
        : index == 1
        ? '/explore'
        : index == 2
        ? '/friend'
        : index == 3
        ? '/settings'
        : '/my-info';
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => GoRouter.of(context).go(route),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary.withValues(alpha: 0.1)
                  : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? AppTheme.primary : AppTheme.textBody,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? AppTheme.primary : AppTheme.textBody,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navSubItem(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
      ),
    );
  }
}
