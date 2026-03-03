import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_config.dart';
import '../../../core/nickname_code_utils.dart';
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
    final content = _isLoading
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
          );

    if (!kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('친구 초대')),
        body: Center(child: content),
      );
    }

    // 웹에서는 먼저 "앱으로 보기 / 웹으로 계속" 선택 배너를 보여준다.
    return Scaffold(
      appBar: AppBar(title: const Text('친구 초대')),
      body: Column(
        children: [
          _WebInviteChoiceBar(token: widget.token),
          Expanded(child: Center(child: content)),
        ],
      ),
    );
  }
}

class _WebInviteChoiceBar extends StatelessWidget {
  final String token;

  const _WebInviteChoiceBar({required this.token});

  Future<void> _openApp() async {
    final uri = Uri.parse('wishdrop://friend?token=$token');
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  Future<void> _openStore() async {
    String url = '';
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      url = AppConfig.appStoreUrl;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      url = AppConfig.playStoreUrl;
    }
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '어디에서 볼까요?',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            '앱이 없으면 먼저 설치하거나, 그대로 모바일 웹에서 이어서 볼 수 있어요.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: _openStore,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: const Text('앱 설치하기'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _openApp,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: const Text('앱에서 열기'),
              ),
            ],
          ),
        ],
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
