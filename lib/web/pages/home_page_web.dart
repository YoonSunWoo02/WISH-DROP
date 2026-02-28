import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme.dart';
import '../../../features/wish/data/project_model.dart';
import '../../../features/wish/data/project_repository.dart';
import '../../../features/wish/presentation/widgets/project_card.dart';

/// 웹 전용 홈 페이지 — 위시 목록 (앱과 동일 UI)
class HomePageWeb extends StatefulWidget {
  const HomePageWeb({super.key});

  @override
  State<HomePageWeb> createState() => _HomePageWebState();
}

class _HomePageWebState extends State<HomePageWeb> {
  final _repository = ProjectRepository();
  int _homeStreamKey = 0;
  String? _userNickname;

  @override
  void initState() {
    super.initState();
    _repository.checkAndCompleteProjects();
    _loadUserNickname();
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
    return StreamBuilder<List<ProjectModel>>(
      key: ValueKey(_homeStreamKey),
      stream: _repository.getProjectsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildErrorState(context);
        }
        final projects = snapshot.data
                ?.where((p) => p.status == 'active')
                .toList() ??
            [];
        if (projects.isEmpty) {
          return _buildEmptyState(context);
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 900
                ? 3
                : constraints.maxWidth > 600
                    ? 2
                    : 1;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      return ProjectCard(
                        project: project,
                        onTap: () => context.push('/project/${project.id}'),
                        animate: false,
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              '연결이 불안정합니다',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textHeading,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
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

  Widget _buildEmptyState(BuildContext context) {
    final name =
        _userNickname?.trim().isNotEmpty == true ? _userNickname! : '회원';
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              Text(
                '$name님, 원하는 선물을 시작해볼까요?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textHeading,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.card_giftcard_rounded,
                      size: 64,
                      color: AppTheme.primary,
                    ),
                    Positioned(
                      top: 28,
                      right: 32,
                      child: Icon(
                        Icons.favorite_rounded,
                        size: 20,
                        color: AppTheme.primary.withOpacity(0.9),
                      ),
                    ),
                    Positioned(
                      bottom: 32,
                      left: 28,
                      child: Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: AppTheme.primary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '아직 등록된 위시가 없어요',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textHeading,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '친구들과 함께 꿈꾸던 선물을 나눠보세요.',
                style: TextStyle(fontSize: 14, color: AppTheme.textBody),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    await context.push('/create');
                    if (mounted) setState(() => _homeStreamKey++);
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 32,
                    ),
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
                          child: const Icon(
                            Icons.add,
                            size: 36,
                            color: Colors.white,
                          ),
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
            ],
          ),
        ),
      ),
    );
  }
}
