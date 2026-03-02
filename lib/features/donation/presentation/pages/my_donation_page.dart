import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/nickname_code_utils.dart';
import '../../../../core/theme.dart';
import '../../../../core/search_history_helper.dart';
import '../../../../core/stagger_fade_in.dart';
import '../../data/donation_repository.dart';

/// 보낸 마음 검색 기록 키 (로컬 저장)
const _kDonationSearchHistoryKey = 'search_history_donation';

/// 보낸 마음(후원 내역) — 월별 헤더 + 검색(닉네임 OR 선물명) + 검색 기록 + 카드
class MyDonationPage extends StatefulWidget {
  /// 후원 직후 이 프로젝트 ID 카드를 잠시 강조 (테두리 플래시)
  final int? highlightedProjectId;

  const MyDonationPage({super.key, this.highlightedProjectId});

  @override
  State<MyDonationPage> createState() => _MyDonationPageState();
}

class _MyDonationPageState extends State<MyDonationPage> {
  final _repo = DonationRepository();
  final _formatter = NumberFormat('#,###');
  final _searchHistory = SearchHistoryHelper(
    storageKey: _kDonationSearchHistoryKey,
    maxItems: 10,
  );
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _donations = [];
  bool _isLoading = true;
  String _query = '';
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _load();
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

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final list = await _repo.getMyDonationsWithCreator();
      if (mounted)
        setState(() {
          _donations = list;
          _isLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 닉네임 또는 선물(프로젝트) 이름에 검색어 포함 여부 (LIKE, 코드 없이 닉네임만 쳐도 매칭)
  bool _matchesQuery(Map<String, dynamic> item) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final projects = item['projects'] as Map<String, dynamic>?;
    final projectTitle = (projects?['title'] as String? ?? '').toLowerCase();
    final creatorNickname = (projects?['creator_nickname'] as String? ?? '')
        .toLowerCase();
    return projectTitle.contains(q) || creatorNickname.contains(q);
  }

  List<Map<String, dynamic>> get _filteredDonations {
    return _donations.where(_matchesQuery).toList();
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

  Map<String, List<Map<String, dynamic>>> _groupByMonth() {
    final list = _filteredDonations;
    final map = <String, List<Map<String, dynamic>>>{};
    for (final d in list) {
      final createdAt = DateTime.parse(
        (d['created_at'] as String).toString(),
      ).toLocal();
      final key = _monthKey(createdAt);
      map.putIfAbsent(key, () => []).add(d);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('보낸 마음'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchBar(),
                _buildSearchHistory(),
                Expanded(
                  child: _donations.isEmpty
                      ? _buildEmpty()
                      : _filteredDonations.isEmpty
                      ? _buildNoResults()
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
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
          hintText: '후원한 사람 이름 또는 선물 이름으로 검색',
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHistory() {
    if (_history.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          '아직 후원한 내역이 없어요.\n친구 위시에 마음을 전해보세요! 💌',
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
          '검색 결과가 없어요.\n다른 단어로 찾아보세요.',
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
    int cardIndex = 0;

    for (final key in keys) {
      final items = grouped[key]!;
      final firstDate = DateTime.parse(
        (items.first['created_at'] as String).toString(),
      ).toLocal();
      final year = firstDate.year;
      final month = firstDate.month;

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

      for (final item in items) {
        final idx = cardIndex++;
        final projectId = item['project_id'] as int?;
        final isHighlighted =
            widget.highlightedProjectId != null &&
            projectId == widget.highlightedProjectId;
        list.add(
          StaggerFadeIn(
            index: idx,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DonationCard(
                item: item,
                formatter: _formatter,
                isHighlighted: isHighlighted,
              ),
            ),
          ),
        );
      }
    }

    list.add(const SizedBox(height: 24));
    return list;
  }
}

class _DonationCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final NumberFormat formatter;
  final bool isHighlighted;

  const _DonationCard({
    required this.item,
    required this.formatter,
    this.isHighlighted = false,
  });

  @override
  State<_DonationCard> createState() => _DonationCardState();
}

class _DonationCardState extends State<_DonationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _highlightController;
  late Animation<double> _highlightOpacity;

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _highlightOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _highlightController, curve: Curves.easeOut),
    );
    if (widget.isHighlighted) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _highlightController.forward();
      });
    }
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final formatter = widget.formatter;
    final projects = item['projects'] as Map<String, dynamic>?;
    final projectTitle = projects?['title'] as String? ?? '삭제된 프로젝트';
    final creatorNickname = projects?['creator_nickname'] as String? ?? '';
    final creatorCode = projects?['creator_friend_code'] as String? ?? '';
    final creatorAvatarUrl = projects?['creator_avatar_url'] as String?;
    final amount = item['amount'] as int? ?? 0;
    final createdAt = DateTime.parse(
      (item['created_at'] as String).toString(),
    ).toLocal();
    final dateLabel = '${createdAt.month}월 ${createdAt.day}일';

    final displayName = (creatorNickname.isNotEmpty || creatorCode.isNotEmpty)
        ? formatNicknameCode(creatorNickname, creatorCode)
        : projectTitle;

    Widget card = Container(
      padding: const EdgeInsets.all(14),
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
          CircleAvatar(
            radius: 26,
            backgroundColor: AppTheme.primary.withOpacity(0.12),
            backgroundImage:
                creatorAvatarUrl != null && creatorAvatarUrl.isNotEmpty
                ? NetworkImage(creatorAvatarUrl)
                : null,
            child: creatorAvatarUrl == null || creatorAvatarUrl.isEmpty
                ? Text(
                    displayName.isNotEmpty ? displayName[0] : '?',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textHeading,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatter.format(amount)}원',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            dateLabel,
            style: TextStyle(fontSize: 13, color: AppTheme.textBody),
          ),
        ],
      ),
    );

    if (!widget.isHighlighted) return card;
    return AnimatedBuilder(
      animation: _highlightController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primary.withOpacity(
                _highlightOpacity.value * 0.9,
              ),
              width: 2,
            ),
          ),
          child: card,
        );
      },
    );
  }
}
