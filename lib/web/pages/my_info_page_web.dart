import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/nickname_code_utils.dart';
import '../../core/theme.dart';
import '../../features/donation/data/donation_repository.dart';
import '../../features/wish/data/project_repository.dart';
import '../../profile/presentation/pages/my_wish_list_page.dart';

/// 웹 전용 마이페이지 — HTML 디자인 (프로필 + 만든 위시/보낸 마음 탭)
class MyInfoPageWeb extends StatefulWidget {
  const MyInfoPageWeb({super.key});

  @override
  State<MyInfoPageWeb> createState() => _MyInfoPageWebState();
}

class _MyInfoPageWebState extends State<MyInfoPageWeb> {
  final _donationRepo = DonationRepository();
  final _projectRepo = ProjectRepository();
  final _searchController = TextEditingController();
  final _formatter = NumberFormat('#,###');

  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _donations = [];
  int _successCount = 0;
  bool _isLoading = true;
  String _query = '';
  bool _tabSent = true; // true: 보낸 마음, false: 만든 위시

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final profileRes = await Supabase.instance.client
          .from('profiles')
          .select('nickname, friend_code, avatar_url')
          .eq('id', userId)
          .maybeSingle();
      final donations = await _donationRepo.getMyDonationsWithCreator();
      final myWishes = await _projectRepo.getMyWishes();
      final successCount = myWishes
          .where((p) => p.status == 'completed')
          .length;

      if (mounted) {
        setState(() {
          _profile = profileRes;
          _donations = donations;
          _successCount = successCount;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _totalFunded {
    return _donations.fold<int>(
      0,
      (sum, d) => sum + ((d['amount'] as int?) ?? 0),
    );
  }

  List<Map<String, dynamic>> get _filteredDonations {
    if (_query.trim().isEmpty) return _donations;
    final q = _query.trim().toLowerCase();
    return _donations.where((d) {
      final p = d['projects'] as Map<String, dynamic>?;
      final title = (p?['title'] as String? ?? '').toLowerCase();
      final nick = (p?['creator_nickname'] as String? ?? '').toLowerCase();
      return title.contains(q) || nick.contains(q);
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> _groupByMonth() {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final d in _filteredDonations) {
      final at = DateTime.parse(
        (d['created_at'] as String).toString(),
      ).toLocal();
      final key = '${at.year}-${at.month}';
      map.putIfAbsent(key, () => []).add(d);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final nickname = _profile?['nickname'] as String? ?? '사용자';
    final friendCode = _profile?['friend_code'] as String? ?? '';
    final avatarUrl = _profile?['avatar_url'] as String?;
    final codeDisplay = formatNicknameCode(nickname, friendCode);

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileSection(
              context,
              codeDisplay,
              nickname,
              friendCode,
              avatarUrl,
            ),
            _tabSent ? _buildSentContent(context) : _buildWishContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(
    BuildContext context,
    String codeDisplay,
    String nickname,
    String friendCode,
    String? avatarUrl,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () =>
                    _navigateEditProfile(nickname, friendCode, avatarUrl),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null || avatarUrl.isEmpty
                          ? Text(
                              (nickname.isEmpty
                                      ? '?'
                                      : nickname.substring(0, 1))
                                  .toUpperCase(),
                              style: const TextStyle(fontSize: 32),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          nickname,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textHeading,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Text(
                            'LV. 3 기부천사',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (codeDisplay != nickname) ...[
                      const SizedBox(height: 4),
                      Text(
                        codeDisplay,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '함께 나누는 기쁨을 알아가는 중 ✨',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _navigateEditProfile(
                            nickname,
                            friendCode,
                            avatarUrl,
                          ),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('프로필 수정'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () => context.push('/settings'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('설정'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      '총 펀딩액',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatter.format(_totalFunded)}원',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                ),
                Column(
                  children: [
                    Text(
                      '성공한 위시',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_successCount개',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _tabButton(
                '🎁 만든 위시',
                !_tabSent,
                () => setState(() => _tabSent = false),
              ),
              _tabButton(
                '💌 보낸 마음',
                _tabSent,
                () => setState(() => _tabSent = true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, bool selected, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppTheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: selected ? AppTheme.primary : AppTheme.textBody,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSentContent(BuildContext context) {
    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '내역 ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_filteredDonations.length}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: '친구 닉네임 또는 선물 검색',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ..._buildMonthSections(),
            ],
          ),
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
      final first = DateTime.parse(
        (items.first['created_at'] as String).toString(),
      ).toLocal();
      final year = first.year;
      final month = first.month;
      final monthTotal = items.fold<int>(
        0,
        (s, d) => s + ((d['amount'] as int?) ?? 0),
      );
      final isCurrentMonth =
          year == DateTime.now().year && month == DateTime.now().month;

      list.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$year년 $month월',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Text(
                  isCurrentMonth
                      ? '이번 달 총 ${_formatter.format(monthTotal)}원을 선물했어요'
                      : '지난 달 총 ${_formatter.format(monthTotal)}원을 선물했어요',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      );

      for (final item in items) {
        list.add(_buildDonationCard(item, isCurrentMonth));
        list.add(const SizedBox(height: 12));
      }
    }

    if (list.isEmpty && _filteredDonations.isEmpty) {
      list.add(
        Center(
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Text(
              '아직 후원한 내역이 없어요.\n친구 위시에 마음을 전해보세요! 💌',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.6,
              ),
            ),
          ),
        ),
      );
    }

    return list;
  }

  Widget _buildDonationCard(Map<String, dynamic> item, bool isCurrentMonth) {
    final p = item['projects'] as Map<String, dynamic>?;
    final title = p?['title'] as String? ?? '';
    final creatorNickname = p?['creator_nickname'] as String? ?? '';
    final creatorCode = p?['creator_friend_code'] as String? ?? '';
    final avatarUrl = p?['creator_avatar_url'] as String?;
    final amount = item['amount'] as int? ?? 0;
    final createdAt = DateTime.parse(
      (item['created_at'] as String).toString(),
    ).toLocal();
    final dateStr = '${createdAt.month}월 ${createdAt.day}일';
    final displayName = formatNicknameCode(creatorNickname, creatorCode);
    final message = item['message'] as String?;
    final isFunding = message == null || message.isEmpty;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          final pid = item['project_id'] as int?;
          if (pid != null) context.push('/project/$pid');
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? Text(
                            (creatorNickname.isEmpty
                                    ? '?'
                                    : creatorNickname.substring(0, 1))
                                .toUpperCase(),
                          )
                        : null,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          size: 12,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isFunding ? '$title 펀딩에 참여함' : '$title 선물함',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dateStr,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    '- ${_formatter.format(amount)}원',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWishContent(BuildContext context) {
    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: MyWishListPage(
            embeddedInScroll: true,
            onWishTap: (p) => context.push('/project/${p.id}'),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateEditProfile(
    String nickname,
    String friendCode,
    String? avatarUrl,
  ) async {
    await context.push(
      '/edit-profile',
      extra: {
        'nickname': nickname,
        'friendCode': friendCode,
        'avatarUrl': avatarUrl,
      },
    );
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            _loadAll();
          } catch (_) {}
        }
      });
    }
  }
}
