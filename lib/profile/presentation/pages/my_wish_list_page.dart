import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme.dart';
import '../../../../core/search_history_helper.dart';
import '../../../features/wish/data/project_repository.dart';
import '../../../features/wish/data/project_model.dart';
import '../../../features/wish/presentation/pages/project_detail_page.dart';

/// 만든 위시 검색 기록 키 (로컬 저장)
const _kWishSearchHistoryKey = 'search_history_wish';

/// 내 위시 기록 — 월별 헤더 + 검색(제목) + 검색 기록 + 상태 필터 + 카드
class MyWishListPage extends StatefulWidget {
  const MyWishListPage({super.key});

  @override
  State<MyWishListPage> createState() => _MyWishListPageState();
}

class _MyWishListPageState extends State<MyWishListPage> {
  final _repo = ProjectRepository();
  final _searchHistory = SearchHistoryHelper(storageKey: _kWishSearchHistoryKey, maxItems: 10);
  final _searchController = TextEditingController();

  List<ProjectModel> _wishes = [];
  bool _isLoading = true;
  String _query = '';
  String _statusFilter = 'all'; // 'all' | 'active' | 'completed' | 'failed'
  List<String> _history = [];

  String get _myId => Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _loadAll();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final list = await _searchHistory.load();
    if (mounted) setState(() => _history = list);
  }

  Future<void> _loadAll() async {
    if (_myId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _repo.checkAndCompleteProjects();
      final list = await _repo.getMyWishes();
      if (mounted) setState(() {
        _wishes = list;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<ProjectModel> get _filteredWishes {
    var list = _wishes;
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((p) => p.title.toLowerCase().contains(q)).toList();
    }
    switch (_statusFilter) {
      case 'active':
        list = list.where((p) => p.isActive).toList();
        break;
      case 'completed':
        list = list.where((p) => p.isCompletedByGoal).toList();
        break;
      case 'failed':
        list = list.where((p) => p.isCompletedByExpiry).toList();
        break;
    }
    return list;
  }

  Future<void> _onSearchSubmitted(String term) async {
    final t = term.trim();
    if (t.isEmpty) return;
    await _searchHistory.add(t);
    await _loadHistory();
    setState(() => _query = t);
  }

  Future<void> _removeHistoryItem(String term) async {
    await _searchHistory.remove(term);
    await _loadHistory();
    setState(() {});
  }

  String _monthKey(DateTime d) => '${d.year}-${d.month}';

  Map<String, List<ProjectModel>> _groupByMonth() {
    final list = _filteredWishes;
    final map = <String, List<ProjectModel>>{};
    for (final p in list) {
      final key = _monthKey(p.createdAt);
      map.putIfAbsent(key, () => []).add(p);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('만든 위시'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchBar(),
                _buildSearchHistory(),
                _buildStatusChips(),
                Expanded(
                  child: _wishes.isEmpty
                      ? _buildEmpty()
                      : _filteredWishes.isEmpty
                          ? _buildNoResults()
                          : RefreshIndicator(
                              onRefresh: _loadAll,
                              child: ListView(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                children: _buildMonthSections(),
                              ),
                            ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _query = v),
        onSubmitted: _onSearchSubmitted,
        decoration: InputDecoration(
          hintText: '위시 제목으로 검색',
          prefixIcon: const Icon(Icons.search, color: AppTheme.textBody),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSearchHistory() {
    if (_history.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              '최근 검색',
              style: TextStyle(fontSize: 12, color: AppTheme.textBody),
            ),
            const SizedBox(width: 8),
            ..._history.map((term) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InputChip(
                  label: Text(term, style: const TextStyle(fontSize: 12)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removeHistoryItem(term),
                  onPressed: () {
                  _searchController.text = term;
                  setState(() => _query = term);
                },
                  backgroundColor: AppTheme.background,
                  side: BorderSide(color: AppTheme.borderColor),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _statusChip('전체', 'all'),
            const SizedBox(width: 8),
            _statusChip('진행 중', 'active'),
            const SizedBox(width: 8),
            _statusChip('달성 완료', 'completed'),
            const SizedBox(width: 8),
            _statusChip('실패', 'failed'),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String label, String value) {
    final selected = _statusFilter == value;
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 13, color: selected ? Colors.white : AppTheme.textBody)),
      selected: selected,
      onSelected: (_) => setState(() => _statusFilter = value),
      selectedColor: AppTheme.primary,
      checkmarkColor: Colors.white,
      side: BorderSide(color: selected ? AppTheme.primary : AppTheme.borderColor),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          '아직 만든 위시가 없어요.\n첫 위시를 만들어보세요! 🎁',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textBody, fontSize: 15, height: 1.5),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          '검색 결과가 없어요.\n다른 단어나 필터로 찾아보세요.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textBody, fontSize: 14, height: 1.5),
        ),
      ),
    );
  }

  List<Widget> _buildMonthSections() {
    final grouped = _groupByMonth();
    final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final list = <Widget>[];

    for (final key in keys) {
      final items = grouped[key]!;
      final first = items.first;
      final year = first.createdAt.year;
      final month = first.createdAt.month;

      list.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10),
          child: Text(
            '$year년 $month월',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textBody,
            ),
          ),
        ),
      );

      for (final project in items) {
        list.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _WishCard(
              project: project,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProjectDetailPage(project: project),
                ),
              ).then((_) => _loadAll()),
            ),
          ),
        );
      }
    }

    list.add(const SizedBox(height: 24));
    return list;
  }
}

class _WishCard extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onTap;

  const _WishCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rate = (project.progressRate * 100).round();
    final isSuccess = project.isCompletedByGoal;
    final isFail = project.isCompletedByExpiry;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppTheme.borderColor.withOpacity(0.6)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: project.thumbnailUrl != null && project.thumbnailUrl!.isNotEmpty
                    ? Image.network(
                        project.thumbnailUrl!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textHeading,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '달성률 $rate%',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textBody,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSuccess)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    '성공',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                )
              else if (isFail)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    '실패',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: const Text(
                    '진행 중',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
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
      width: 64,
      height: 64,
      color: AppTheme.primary.withOpacity(0.12),
      child: const Icon(Icons.card_giftcard_rounded, color: AppTheme.primary, size: 28),
    );
  }
}
