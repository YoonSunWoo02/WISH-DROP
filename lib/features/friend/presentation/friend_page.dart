import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../friend/data/friend_repository.dart';
import '../../friend/data/friendship_model.dart';
import '../../friend/data/profile_model.dart';
import 'friend_wish_page.dart';

class FriendPage extends StatefulWidget {
  const FriendPage({super.key});

  @override
  State<FriendPage> createState() => _FriendPageState();
}

class _FriendPageState extends State<FriendPage> {
  final _repo = FriendRepository(supabase: Supabase.instance.client);

  List<FriendModel> _friends = [];
  List<FriendRequestModel> _requests = [];
  List<SentRequestModel> _sentRequests = [];
  ProfileModel? _myProfile;
  bool _isLoading = true;
  final _codeController = TextEditingController();
  bool _codeSending = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[FriendPage] initState');
    _loadAll();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    debugPrint('[FriendPage] _loadAll start');
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repo.fetchFriends(),
        _repo.fetchPendingRequests(),
        _repo.fetchSentPendingRequests(),
        _repo.fetchMyProfile(),
      ]);
      setState(() {
        _friends = results[0] as List<FriendModel>;
        _requests = results[1] as List<FriendRequestModel>;
        _sentRequests = results[2] as List<SentRequestModel>;
        _myProfile = results[3] as ProfileModel?;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
    debugPrint(
        '[FriendPage] _loadAll done, friends=${_friends.length}, requests=${_requests.length}, sent=${_sentRequests.length}, hasProfile=${_myProfile != null}');
  }

  Future<void> _cancelSentRequest(SentRequestModel sent) async {
    await _repo.cancelSentRequest(sent.id);
    _loadAll();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('요청을 취소했어요')),
      );
    }
  }

  Future<void> _addFriendByCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('친구 코드를 입력해 주세요')),
      );
      return;
    }
    setState(() => _codeSending = true);
    try {
      final user = await _repo.findUserByCode(code);
      if (!mounted) return;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('해당 코드의 사용자를 찾을 수 없어요')),
        );
        return;
      }
      final status = await _repo.getFriendshipStatus(user.id);
      if (status == 'accepted') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 친구예요')),
        );
        return;
      }
      if (status == 'pending') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 친구 요청을 보냈어요 (대기 중)')),
        );
        return;
      }
      await _repo.sendFriendRequest(user.id);
      _codeController.clear();
      _loadAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('친구 요청을 보냈어요. 수락하면 친구가 돼요')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('요청 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _codeSending = false);
    }
  }

  Future<void> _accept(FriendRequestModel req) async {
    await _repo.acceptFriendRequest(req.id);
    _loadAll();
  }

  Future<void> _reject(FriendRequestModel req) async {
    await _repo.rejectFriendRequest(req.id);
    _loadAll();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('요청을 거절했어요')),
      );
    }
  }

  Future<void> _removeFriend(FriendModel friend) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('친구 삭제'),
        content: Text(
          '${friend.nickname}님과 친구 관계를 끊을까요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await _repo.removeFriend(friend.friendshipId);
    _loadAll();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('친구를 삭제했어요')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('친구')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView(
                children: [
                  _AddFriendByCodeCard(
                    controller: _codeController,
                    sending: _codeSending,
                    onSend: _addFriendByCode,
                  ),
                  _SectionHeader(
                    title: '받은 친구 요청',
                    badge: _requests.isNotEmpty ? _requests.length : null,
                  ),
                  if (_requests.isNotEmpty)
                    ..._requests.map(
                      (req) => _RequestCard(
                        request: req,
                        onAccept: () => _accept(req),
                        onReject: () => _reject(req),
                      ),
                    ),
                  if (_requests.isEmpty)
                    const _ReceivedRequestsEmptyHint(),
                  const SizedBox(height: 8),
                  if (_myProfile != null)
                    _MyCodeTile(
                      profile: _myProfile!,
                      onCopy: () {
                        Clipboard.setData(
                          ClipboardData(text: _myProfile!.friendCode),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('내 코드를 복사했어요')),
                        );
                      },
                    ),
                  if (_sentRequests.isNotEmpty) ...[
                    _SectionHeader(title: '보낸 친구 요청 (대기 중)'),
                    ..._sentRequests.map(
                      (sent) => _SentRequestCard(
                        sent: sent,
                        onCancel: () => _cancelSentRequest(sent),
                      ),
                    ),
                  ],
                  _SectionHeader(title: '친구 ${_friends.length}명'),
                  if (_friends.isEmpty)
                    const _EmptyFriends()
                  else
                    ..._friends.map(
                      (f) => _FriendTile(
                        friend: f,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FriendWishPage(friend: f),
                          ),
                        ),
                        onRemove: () => _removeFriend(f),
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _AddFriendByCodeCard extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _AddFriendByCodeCard({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
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
          Text(
            '친구 추가',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: '닉네임#1234',
                    hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  textCapitalization: TextCapitalization.none,
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: sending ? null : onSend,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('친구 요청'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceivedRequestsEmptyHint extends StatelessWidget {
  const _ReceivedRequestsEmptyHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Text(
        '친구가 내 코드를 입력하고 요청하면 여기에 표시돼요.',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
    );
  }
}

class _MyCodeTile extends StatelessWidget {
  final ProfileModel profile;
  final VoidCallback? onCopy;

  const _MyCodeTile({required this.profile, this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.tag, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '내 코드  ',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          Text(
            profile.friendCode,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          if (onCopy != null)
            TextButton(
              onPressed: onCopy,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('복사', style: TextStyle(fontSize: 13)),
            )
          else
            const Text(
              '친구에게 알려주세요',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int? badge;

  const _SectionHeader({required this.title, this.badge});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SentRequestCard extends StatelessWidget {
  final SentRequestModel sent;
  final VoidCallback onCancel;

  const _SentRequestCard({required this.sent, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          _Avatar(
            avatarUrl: sent.receiverAvatarUrl,
            nickname: sent.receiverNickname,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sent.receiverNickname,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  sent.receiverCode,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  '수락 대기 중',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onCancel,
            child: const Text(
              '요청 취소',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final FriendRequestModel request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          _Avatar(
            avatarUrl: request.requesterAvatarUrl,
            nickname: request.requesterNickname,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.requesterNickname,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  request.requesterCode,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onReject,
            child: const Text(
              '거절',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: onAccept,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('수락'),
          ),
        ],
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final FriendModel friend;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _FriendTile({
    required this.friend,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _Avatar(
        avatarUrl: friend.avatarUrl,
        nickname: friend.nickname,
      ),
      title: Text(
        friend.nickname,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        friend.friendCode,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (friend.activeWishCount > 0) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '위시 ${friend.activeWishCount}개',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          if (onRemove != null) ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
              padding: EdgeInsets.zero,
              onSelected: (value) {
                if (value == 'remove') {
                  onRemove!();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem<String>(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('친구 삭제', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
          ],
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
    );
  }
}

class _EmptyFriends extends StatelessWidget {
  const _EmptyFriends();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('👥', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text(
            '아직 친구가 없어요',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            '친구 코드를 입력해서\n친구를 추가해 보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final String nickname;

  const _Avatar({this.avatarUrl, required this.nickname});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundImage:
          avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      child: avatarUrl == null
          ? Text(
              nickname.isNotEmpty ? nickname[0] : '?',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}

