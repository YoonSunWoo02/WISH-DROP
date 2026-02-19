import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme.dart';
import '../../../features/wish/data/project_repository.dart';
import '../../../features/wish/data/project_model.dart';
import '../../../features/wish/presentation/widgets/project_card.dart';
import '../../../features/wish/presentation/pages/project_detail_page.dart';

/// 내 위시 기록 — status 기반 진행 중 / 종료됨 탭
class MyWishListPage extends StatefulWidget {
  const MyWishListPage({super.key});

  @override
  State<MyWishListPage> createState() => _MyWishListPageState();
}

class _MyWishListPageState extends State<MyWishListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _repo = ProjectRepository();

  List<ProjectModel> _active = [];
  List<ProjectModel> _completed = [];
  bool _isLoading = true;

  String get _myId => Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    if (_myId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _repo.checkAndCompleteProjects();
      final active = await _repo.fetchMyActiveProjects(_myId);
      final completed = await _repo.fetchMyCompletedProjects(_myId);
      if (mounted) {
        setState(() {
          _active = active;
          _completed = completed;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goDetail(ProjectModel p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectDetailPage(project: p),
      ),
    ).then((_) => _loadAll());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("내 위시 기록"),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(child: _TabLabel(text: '진행 중', count: _active.length)),
            Tab(child: _TabLabel(text: '종료됨', count: _completed.length)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildWishList(
                    _active,
                    "진행 중인 위시가 없어요.\n새 위시를 만들어보세요! 🎁",
                    isCompleted: false,
                  ),
                  _buildWishList(
                    _completed,
                    "종료된 위시가 없어요.",
                    isCompleted: true,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildWishList(
    List<ProjectModel> wishes,
    String emptyMessage, {
    required bool isCompleted,
  }) {
    if (wishes.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: wishes.length,
      itemBuilder: (context, index) {
        final project = wishes[index];
        return ProjectCard(
          project: project,
          onTap: () => _goDetail(project),
        );
      },
    );
  }
}

class _TabLabel extends StatelessWidget {
  final String text;
  final int count;
  const _TabLabel({required this.text, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
