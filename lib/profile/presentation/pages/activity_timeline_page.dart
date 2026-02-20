import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme.dart';
import '../../../features/wish/data/project_model.dart';
import '../../../features/wish/data/project_repository.dart';
import '../../../features/wish/presentation/pages/project_detail_page.dart';
import '../../../features/donation/data/donation_repository.dart';

/// 타임라인 이벤트: 위시 생성 | 후원
enum TimelineEventType { wishCreated, donation }

class TimelineEvent {
  final TimelineEventType type;
  final DateTime date;

  /// 위시 생성일 때
  final ProjectModel? project;

  /// 후원일 때
  final int? amount;
  final String? projectTitle;
  final int? projectId;

  const TimelineEvent({
    required this.type,
    required this.date,
    this.project,
    this.amount,
    this.projectTitle,
    this.projectId,
  });
}

/// 내 위시 기록 + 후원 내역을 날짜순 타임라인으로 표시
class ActivityTimelinePage extends StatefulWidget {
  const ActivityTimelinePage({super.key});

  @override
  State<ActivityTimelinePage> createState() => _ActivityTimelinePageState();
}

class _ActivityTimelinePageState extends State<ActivityTimelinePage> {
  final _projectRepo = ProjectRepository();
  final _donationRepo = DonationRepository();
  final _numberFormat = NumberFormat('#,###');

  List<TimelineEvent> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final wishes = await _projectRepo.getMyWishes();
      final donations = await _donationRepo.getMyDonations();

      final events = <TimelineEvent>[
        ...wishes.map((p) => TimelineEvent(
              type: TimelineEventType.wishCreated,
              date: p.createdAt,
              project: p,
            )),
        ...donations.map((d) {
          final createdAt = DateTime.parse((d['created_at'] as String).toString()).toLocal();
          final projects = d['projects'] as Map<String, dynamic>?;
          final title = projects?['title'] as String? ?? '삭제된 프로젝트';
          final projectId = d['project_id'] as int?;
          return TimelineEvent(
            type: TimelineEventType.donation,
            date: createdAt,
            amount: d['amount'] as int? ?? 0,
            projectTitle: title,
            projectId: projectId,
          );
        }),
      ];

      events.sort((a, b) => b.date.compareTo(a.date));

      if (mounted) setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _events = [];
        _isLoading = false;
      });
    }
  }

  /// 날짜별로 그룹 (같은 날짜 키)
  String _dateKey(DateTime d) {
    return '${d.year}-${d.month}-${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('내 활동'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTimeline,
              child: _events.isEmpty
                  ? _buildEmpty()
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      children: _buildTimelineChildren(),
                    ),
            ),
    );
  }

  Widget _buildEmpty() {
    return const SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            '아직 위시 기록이나 후원 내역이 없어요.\n첫 위시를 만들거나 친구를 후원해보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textBody, fontSize: 15, height: 1.5),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTimelineChildren() {
    final children = <Widget>[];
    String? lastDateKey;

    for (int i = 0; i < _events.length; i++) {
      final event = _events[i];
      final dateKey = _dateKey(event.date);
      final isFirstInGroup = dateKey != lastDateKey;
      final isLast = i == _events.length - 1;
      lastDateKey = dateKey;

      if (isFirstInGroup) {
        if (children.isNotEmpty) children.add(const SizedBox(height: 8));
        children.add(_TimelineRow(
          showDateNode: true,
          date: event.date,
          showLineBelow: true,
          child: _BubbleCard(
            event: event,
            numberFormat: _numberFormat,
            onWishTap: event.project != null
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProjectDetailPage(project: event.project!),
                      ),
                    ).then((_) => _loadTimeline())
                : null,
            onDonationTap: event.projectId != null
                ? () async {
                    final p = await _projectRepo.fetchProjectById(event.projectId!);
                    if (p != null && mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectDetailPage(project: p),
                        ),
                      ).then((_) => _loadTimeline());
                    }
                  }
                : null,
          ),
        ));
      } else {
        children.add(_TimelineRow(
          showDateNode: false,
          date: event.date,
          showLineBelow: !isLast,
          child: _BubbleCard(
            event: event,
            numberFormat: _numberFormat,
            onWishTap: event.project != null
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProjectDetailPage(project: event.project!),
                      ),
                    ).then((_) => _loadTimeline())
                : null,
            onDonationTap: event.projectId != null
                ? () async {
                    final p = await _projectRepo.fetchProjectById(event.projectId!);
                    if (p != null && mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectDetailPage(project: p),
                        ),
                      ).then((_) => _loadTimeline());
                    }
                  }
                : null,
          ),
        ));
      }
    }

    children.add(const SizedBox(height: 32));
    return children;
  }
}

/// 한 줄: 왼쪽 수직선(점 위아래로 이어짐) + 날짜 점 + 오른쪽 말풍선 카드
class _TimelineRow extends StatelessWidget {
  final bool showDateNode;
  final DateTime date;
  final bool showLineBelow;
  final Widget child;

  const _TimelineRow({
    required this.showDateNode,
    required this.date,
    required this.showLineBelow,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = '${date.month}/${date.day}';
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Center(
                    child: Container(
                      width: 2,
                      color: AppTheme.borderColor,
                    ),
                  ),
                ),
                if (showDateNode) ...[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textBody,
                    ),
                  ),
                  const SizedBox(height: 4),
                ] else
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppTheme.borderColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (showLineBelow)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2,
                        color: AppTheme.borderColor,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 24),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// 말풍선 형태 카드
class _BubbleCard extends StatelessWidget {
  final TimelineEvent event;
  final NumberFormat numberFormat;
  final VoidCallback? onWishTap;
  final VoidCallback? onDonationTap;

  const _BubbleCard({
    required this.event,
    required this.numberFormat,
    this.onWishTap,
    this.onDonationTap,
  });

  @override
  Widget build(BuildContext context) {
    final isWish = event.type == TimelineEventType.wishCreated;
    final text = isWish
        ? '${event.project?.title ?? ''} 위시를 생성했어요.'
        : '${event.projectTitle ?? ''} 위시에 ${numberFormat.format(event.amount ?? 0)}원을 후원했어요.';
    final icon = isWish ? Icons.card_giftcard_rounded : Icons.volunteer_activism_rounded;

    return Padding(
      padding: const EdgeInsets.only(left: 44),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isWish ? onWishTap : onDonationTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textHeading,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
