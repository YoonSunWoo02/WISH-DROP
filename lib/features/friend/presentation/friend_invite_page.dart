import 'package:flutter/material.dart';
import '../../../core/nickname_code_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../friend/data/friend_repository.dart';
import '../../friend/data/profile_model.dart';

class FriendInvitePage extends StatefulWidget {
  final String token;

  const FriendInvitePage({super.key, required this.token});

  @override
  State<FriendInvitePage> createState() => _FriendInvitePageState();
}

class _FriendInvitePageState extends State<FriendInvitePage> {
  final _repo = FriendRepository(supabase: Supabase.instance.client);
  ProfileModel? _inviter;
  bool _isLoading = true;
  bool _isSending = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await _repo.fetchProfileByToken(widget.token);
      setState(() => _inviter = profile);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _accept() async {
    if (_inviter == null) return;
    setState(() => _isSending = true);
    try {
      await _repo.sendRequestByToken(widget.token, _inviter!.id);
      setState(() => _done = true);
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('친구 초대')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _inviter == null
            ? const Text('유효하지 않은 초대 링크예요')
            : _done
            ? _DoneView(
                nickname: _inviter!.nickname,
                onConfirm: () => Navigator.pop(context),
              )
            : _InviteView(
                inviter: _inviter!,
                isSending: _isSending,
                onAccept: _accept,
                onLater: () => Navigator.pop(context),
              ),
      ),
    );
  }
}

class _InviteView extends StatelessWidget {
  final ProfileModel inviter;
  final bool isSending;
  final VoidCallback onAccept;
  final VoidCallback onLater;

  const _InviteView({
    required this.inviter,
    required this.isSending,
    required this.onAccept,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 44,
            backgroundImage: inviter.avatarUrl != null
                ? NetworkImage(inviter.avatarUrl!)
                : null,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: inviter.avatarUrl == null
                ? Text(
                    inviter.nickname[0],
                    style: const TextStyle(fontSize: 32),
                  )
                : null,
          ),
          const SizedBox(height: 20),
          Text(
            '${inviter.nickname}님이\n친구를 신청했어요!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            formatNicknameCode(inviter.nickname, inviter.friendCode),
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 36),
          ElevatedButton(
            onPressed: isSending ? null : onAccept,
            style: ElevatedButton.styleFrom(minimumSize: const Size(220, 52)),
            child: isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('친구 수락하기', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onLater,
            child: const Text('나중에', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

class _DoneView extends StatelessWidget {
  final String nickname;
  final VoidCallback onConfirm;

  const _DoneView({required this.nickname, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🎉', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text(
          '$nickname님에게\n친구 요청을 보냈어요!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('상대방이 수락하면 친구가 돼요', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 32),
        ElevatedButton(onPressed: onConfirm, child: const Text('확인')),
      ],
    );
  }
}
