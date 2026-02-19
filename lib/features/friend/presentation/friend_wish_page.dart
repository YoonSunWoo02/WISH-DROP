import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../wish/data/project_model.dart';
import '../../wish/presentation/pages/project_detail_page.dart';
import '../data/friendship_model.dart';

class FriendWishPage extends StatefulWidget {
  final FriendModel friend;

  const FriendWishPage({super.key, required this.friend});

  @override
  State<FriendWishPage> createState() => _FriendWishPageState();
}

class _FriendWishPageState extends State<FriendWishPage> {
  List<ProjectModel> _wishes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWishes();
  }

  Future<void> _loadWishes() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('projects')
          .select()
          .eq('creator_id', widget.friend.friendId)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      setState(() {
        _wishes = (res as List)
            .map((e) => ProjectModel.fromJson(e))
            .toList();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.friend.avatarUrl != null
                  ? NetworkImage(widget.friend.avatarUrl!)
                  : null,
              backgroundColor:
                  Theme.of(context).primaryColor.withOpacity(0.1),
              child: widget.friend.avatarUrl == null
                  ? Text(
                      widget.friend.nickname[0],
                      style: const TextStyle(fontSize: 13),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text('${widget.friend.nickname}의 위시'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _wishes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🎁', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text(
                        '진행 중인 위시가 없어요',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _wishes.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final wish = _wishes[i];
                    return _WishCard(
                      wish: wish,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ProjectDetailPage(project: wish),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _WishCard extends StatelessWidget {
  final ProjectModel wish;
  final VoidCallback onTap;

  const _WishCard({required this.wish, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (wish.thumbnailUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  wish.thumbnailUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wish.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (wish.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      wish.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: wish.progressRate,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(wish.progressRate * 100).toStringAsFixed(0)}% 달성',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_fmt(wish.currentAmount)} / ${_fmt(wish.targetAmount)}원',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  if (wish.endDate != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 12,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'D-${wish.daysLeft ?? '-'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int v) => v.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}

