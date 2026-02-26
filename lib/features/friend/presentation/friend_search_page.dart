import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../friend/data/friend_repository.dart';
import '../../friend/data/profile_model.dart';

class FriendSearchPage extends StatefulWidget {
  const FriendSearchPage({super.key});

  @override
  State<FriendSearchPage> createState() => _FriendSearchPageState();
}

class _FriendSearchPageState extends State<FriendSearchPage> {
  final _repo = FriendRepository(supabase: Supabase.instance.client);
  final _controller = TextEditingController();
  List<ProfileModel> _results = [];
  final Map<String, String?> _statusCache = {};
  bool _isLoading = false;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final results = await _repo.searchUsers(query);
      for (final user in results) {
        _statusCache[user.id] = await _repo.getFriendshipStatus(user.id);
      }
      setState(() => _results = results);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendRequest(String userId) async {
    try {
      await _repo.sendFriendRequest(userId);
      setState(() => _statusCache[userId] = 'pending');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '친구 요청을 보냈어요! 상대방이 수락하면 친구가 돼요.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('코드로 친구 찾기')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '닉네임 또는 코드 입력 (예: 김철수#1234)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _results = []);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) {
                setState(() {});
                _search(v);
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty && _controller.text.isNotEmpty
                    ? const Center(
                        child: Text(
                          '검색 결과가 없어요',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (_, i) {
                          final user = _results[i];
                          final status = _statusCache[user.id];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user.avatarUrl != null
                                  ? NetworkImage(user.avatarUrl!)
                                  : null,
                              child: user.avatarUrl == null
                                  ? Text(user.nickname[0])
                                  : null,
                            ),
                            title: Text(user.nickname),
                            subtitle: Text(
                              user.friendCode,
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: switch (status) {
                              'accepted' =>
                                const Chip(label: Text('친구 ✓')),
                              'pending' =>
                                const Chip(label: Text('요청 중')),
                              _ => ElevatedButton(
                                  onPressed: () => _sendRequest(user.id),
                                  child: const Text('친구 신청'),
                                ),
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

