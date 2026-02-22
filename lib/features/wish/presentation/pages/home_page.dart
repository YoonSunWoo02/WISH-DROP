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
  /// 후원 직후 게이지 애니메이션을 트리거할 project ID.
  /// null이면 모든 카드 애니메이션 없이 즉시 표시.
  final int? animateProjectId;

  const HomePage({
    super.key,
    this.animateProjectId,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _homeStreamKey = 0;
  String? _userNickname;
  int? _animateProjectId;
  final ProjectRepository _repository = ProjectRepository();
  final _appLinks = AppLinks();
  final _friendRepo = FriendRepository(supabase: Supabase.instance.client);
  int _friendRequestCount = 0;
  late AnimationController _badgePulseController;
  late Animation<double> _badgeScale;

  @override
  void initState() {
    super.initState();
    _animateProjectId = widget.animateProjectId;
    _badgePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _badgeScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _badgePulseController,
      curve: Curves.easeOut,
    ));
    _repository.checkAndCompleteProjects();
    _loadRequestCount();
    _loadUserNickname();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _badgePulseController.dispose();
    super.dispose();
  }

  Future<void> _loadUserNickname() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final data = await Supabase.instance.client
        .from('profiles')
        .select('nickname')
        .eq('id', userId)
        .maybeSingle();
    if (!mounted) return;
    setState(() => _userNickname = data?['nickname'] as String?);
  }

  Future<void> _loadRequestCount() async {
    final count = await _friendRepo.fetchPendingRequestCount();
    if (!mounted) return;
    setState(() {
      final prev = _friendRequestCount;
      _friendRequestCount = count;
      if (count > prev) _badgePulseController.forward(from: 0);
    });
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
      key: ValueKey(_homeStreamKey),
      stream: _repository.getProjectsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    '연결이 불안정합니다',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textHeading,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '잠시 후 다시 시도해 주세요.',
                    style: TextStyle(fontSize: 14, color: AppTheme.textBody),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => setState(() => _homeStreamKey++),
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('다시 시도'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyWishState(context);
        }

        // 종료 체크 후 active만 노출
        final projects = snapshot.data!
            .where((p) => p.status == 'active')
            .toList();
        if (projects.isEmpty) {
          return _buildEmptyWishState(context);
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
              animate: _animateProjectId == project.id,
              onAnimationEnd: () {
                if (mounted) setState(() => _animateProjectId = null);
              },
            );
          },
        );
      },
    );
  }

  /// 위시가 없을 때: 사용자 이름 + 안내 문구 + 위시 등록 버튼
  Widget _buildEmptyWishState(BuildContext context) {
    final name = _userNickname?.trim().isNotEmpty == true
        ? _userNickname!
        : '회원';
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          Text(
            '$name님, 원하는 선물을 시작해볼까요?',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textHeading,
            ),
          ),
          const SizedBox(height: 32),
          // 일러스트: 보라 테두리 박스 + 선물상자 + 하트/반짝이
          Center(
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.card_giftcard_rounded, size: 64, color: AppTheme.primary),
                  Positioned(top: 28, right: 32, child: Icon(Icons.favorite_rounded, size: 20, color: AppTheme.primary.withOpacity(0.9))),
                  Positioned(bottom: 32, left: 28, child: Icon(Icons.auto_awesome, size: 18, color: AppTheme.primary.withOpacity(0.8))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              '아직 등록된 위시가 없어요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textHeading,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              '친구들과 함께 꿈꾸던 선물을 나눠보세요.',
              style: TextStyle(fontSize: 14, color: AppTheme.textBody),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          // CTA: 첫 번째 위시 만들기 버튼
          Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final newId = await Navigator.push<int>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateWishPage(),
                    ),
                  );
                  if (newId != null && mounted) {
                    setState(() => _animateProjectId = newId);
                  }
                },
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add, size: 36, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '첫 번째 위시를 만들어보세요!',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textHeading,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          // TIP
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lightbulb_outline, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                'TIP',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
              ),
              const SizedBox(width: 6),
              Text(
                '인기 있는 선물 리스트를 구경해보세요.',
                style: TextStyle(fontSize: 12, color: AppTheme.textBody),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
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
                  onPressed: () async {
                    final newId = await Navigator.push<int>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateWishPage(),
                      ),
                    );
                    if (newId != null && mounted) {
                      setState(() => _animateProjectId = newId);
                    }
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
            icon: ScaleTransition(
              scale: _badgeScale,
              child: Badge(
                isLabelVisible: _friendRequestCount > 0,
                label: Text('$_friendRequestCount'),
                child: const Icon(Icons.people_outline),
              ),
            ),
            activeIcon: ScaleTransition(
              scale: _badgeScale,
              child: Badge(
                isLabelVisible: _friendRequestCount > 0,
                label: Text('$_friendRequestCount'),
                child: const Icon(Icons.people),
              ),
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
