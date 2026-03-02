import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme.dart';
import '../../../features/wish/data/project_model.dart';
import '../../../features/wish/data/project_repository.dart';

/// 웹 홈 — 환영 배너 + 위시 피드
class HomePageWeb extends StatefulWidget {
  const HomePageWeb({super.key});

  @override
  State<HomePageWeb> createState() => _HomePageWebState();
}

class _HomePageWebState extends State<HomePageWeb> {
  final _repository = ProjectRepository();
  int _homeStreamKey = 0;
  String? _userNickname;
  bool _useFallbackFetch = false;
  Future<List<ProjectModel>>? _fallbackFuture;

  @override
  void initState() {
    super.initState();
    _repository.checkAndCompleteProjects();
    _loadUserNickname();
  }

  Future<void> _retry() async {
    setState(() {
      _useFallbackFetch = true;
      _fallbackFuture = _repository.getProjects();
    });
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

  @override
  Widget build(BuildContext context) {
    if (_useFallbackFetch && _fallbackFuture != null) {
      return FutureBuilder<List<ProjectModel>>(
        future: _fallbackFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildError(context);
          }
          final projects =
              snapshot.data?.where((p) => p.status == 'active').toList() ?? [];
          if (projects.isEmpty) {
            return _buildEmpty(context);
          }
          return _buildContent(context, projects);
        },
      );
    }

    return StreamBuilder<List<ProjectModel>>(
      key: ValueKey(_homeStreamKey),
      stream: _repository.getProjectsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildError(context);
        }
        final projects =
            snapshot.data?.where((p) => p.status == 'active').toList() ?? [];
        if (projects.isEmpty) {
          return _buildEmpty(context);
        }
        return _buildContent(context, projects);
      },
    );
  }

  Widget _buildContent(BuildContext context, List<ProjectModel> projects) {
    final name = _userNickname?.trim().isNotEmpty == true
        ? _userNickname!
        : '회원';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBanner(context, name),
              const SizedBox(height: 32),
              _buildFeedHeader(context),
              const SizedBox(height: 20),
              _buildGrid(context, projects),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context, String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF4338CA)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$name님, 친구들의 소원을 응원해주세요! 👋',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '이번 달 생일인 친구가 있다면, 작게나마 마음을 표현해보는 건 어떨까요?',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _bannerBtn('친구 찾기', true, () => context.go('/friend')),
              const SizedBox(width: 12),
              _bannerBtn('내 위시 공유', false, () => context.push('/create')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bannerBtn(String label, bool primary, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: primary ? Colors.white : Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: primary ? AppTheme.primary : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.dynamic_feed, color: AppTheme.primary, size: 22),
            SizedBox(width: 8),
            Text(
              '친구들의 위시 피드',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textHeading,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '인기순',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '최신순',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, List<ProjectModel> projects) {
    final w = MediaQuery.of(context).size.width;
    final crossCount = w > 900
        ? 3
        : w > 600
        ? 2
        : 1;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        childAspectRatio: 0.72,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: projects.length,
      itemBuilder: (context, i) => _WishCard(
        project: projects[i],
        onTap: () => context.push('/project/${projects[i].id}'),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('오류가 발생했습니다.'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _retry, child: const Text('다시 시도')),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('등록된 위시가 없습니다.'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await context.push('/create');
              if (mounted) setState(() => _homeStreamKey++);
            },
            child: const Text('위시 만들기'),
          ),
        ],
      ),
    );
  }
}

class _WishCard extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onTap;

  const _WishCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final endDate = project.endDate ?? DateTime.now();
    final dDay = endDate.difference(DateTime.now()).inDays;
    final dDayText = dDay >= 0 ? 'D-$dDay' : '종료';
    final progress = project.targetAmount > 0
        ? (project.currentAmount / project.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final fmt = NumberFormat('#,###');

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: SizedBox(
                      height: 160,
                      width: double.infinity,
                      child:
                          project.thumbnailUrl != null &&
                              project.thumbnailUrl!.isNotEmpty
                          ? Image.network(
                              project.thumbnailUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder(),
                            )
                          : _placeholder(),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: dDay <= 7
                              ? Colors.red.shade100
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Text(
                        dDayText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: dDay <= 7
                              ? Colors.red.shade600
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textHeading,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project.description ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textBody,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress >= 1 ? Colors.green : AppTheme.primary,
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${fmt.format(project.currentAmount)}원',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textBody,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}% 달성',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textBody,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onTap,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '응원하기',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 40, color: Colors.grey),
      ),
    );
  }
}
