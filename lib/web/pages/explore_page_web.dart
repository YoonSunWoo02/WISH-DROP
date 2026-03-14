import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../features/wish/data/project_model.dart';
import '../../../features/wish/data/project_repository.dart';

/// 탐색 페이지 — 전체 위시 피드 (친구 외 공개 위시 탐색)
class ExplorePageWeb extends StatefulWidget {
  const ExplorePageWeb({super.key});

  @override
  State<ExplorePageWeb> createState() => _ExplorePageWebState();
}

class _ExplorePageWebState extends State<ExplorePageWeb> {
  final _repository = ProjectRepository();
  bool _useFallback = false;
  Future<List<ProjectModel>>? _fallbackFuture;

  @override
  void initState() {
    super.initState();
    _repository.checkAndCompleteProjects();
  }

  Future<void> _retry() async {
    setState(() {
      _useFallback = true;
      _fallbackFuture = _repository.fetchActiveProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_useFallback && _fallbackFuture != null) {
      return FutureBuilder<List<ProjectModel>>(
        future: _fallbackFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildError(context);
          }
          final projects = snapshot.data ?? [];
          return _buildContent(context, projects);
        },
      );
    }

    return FutureBuilder<List<ProjectModel>>(
      future: _repository.fetchActiveProjects(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildError(context);
        }
        final projects = snapshot.data ?? [];
        return _buildContent(context, projects);
      },
    );
  }

  Widget _buildContent(BuildContext context, List<ProjectModel> projects) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.explore, color: AppTheme.primary, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    '탐색',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textHeading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '다양한 위시를 구경하고 마음을 전해보세요.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              projects.isEmpty
                  ? _buildEmpty(context)
                  : _buildGrid(context, projects),
            ],
          ),
        ),
      ),
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
        childAspectRatio: 0.58,
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

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.card_giftcard_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '아직 등록된 위시가 없어요.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => context.push('/create'),
              child: const Text('첫 위시 만들기'),
            ),
          ],
        ),
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
}

/// 홈과 동일한 위시 카드 (달성률, D-Day)
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
                      height: 320,
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
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
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          foregroundColor: AppTheme.textHeading,
                        ),
                        child: const Text(
                          '응원하기',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
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
