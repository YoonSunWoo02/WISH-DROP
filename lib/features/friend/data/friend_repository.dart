import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import 'package:wish_drop/core/app_config.dart';
import 'profile_model.dart';
import 'friendship_model.dart';

class FriendRepository {
  final SupabaseClient supabase;

  FriendRepository({required this.supabase});

  String get _myId => supabase.auth.currentUser?.id ?? '';

  Future<ProfileModel?> fetchMyProfile() async {
    if (_myId.isEmpty) return null;
    final res = await supabase
        .from('profiles')
        .select()
        .eq('id', _myId)
        .maybeSingle();
    if (res == null) return null;
    return ProfileModel.fromJson(res);
  }

  Future<List<FriendModel>> fetchFriends() async {
    if (_myId.isEmpty) return [];
    final res = await supabase
        .from('friendships')
        .select('''
          id,
          requester_id,
          receiver_id
        ''')
        .eq('status', 'accepted')
        .or('requester_id.eq.$_myId,receiver_id.eq.$_myId');

    final friends = <FriendModel>[];
    for (final row in res as List) {
      final isRequester = row['requester_id'] == _myId;
      final friendId = isRequester
          ? row['receiver_id'] as String
          : row['requester_id'] as String;

      final profileRes = await supabase
          .from('profiles')
          .select()
          .eq('id', friendId)
          .maybeSingle();
      if (profileRes == null) continue;

      final List<dynamic> wishCountRes = await supabase
          .from('projects')
          .select('id')
          .eq('creator_id', friendId)
          .eq('status', 'active');

      friends.add(FriendModel(
        friendshipId: row['id'] as int,
        friendId: friendId,
        nickname: profileRes['nickname'] as String,
        friendCode: profileRes['friend_code'] as String,
        avatarUrl: profileRes['avatar_url'] as String?,
        activeWishCount: wishCountRes.length,
      ));
    }
    return friends;
  }

  /// 받은 친구 요청 (나에게 온 요청) — 조인 없이 조회 후 프로필 따로 불러오기
  Future<List<FriendRequestModel>> fetchPendingRequests() async {
    if (_myId.isEmpty) return [];
    final res = await supabase
        .from('friendships')
        .select('id, requester_id, created_at')
        .eq('receiver_id', _myId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    final list = res as List;
    if (list.isEmpty) return [];

    final requesterIds =
        list.map((e) => e['requester_id'] as String).toSet().toList();
    final profilesRes = await supabase
        .from('profiles')
        .select('id, nickname, friend_code, avatar_url')
        .inFilter('id', requesterIds);
    final profileMap = {
      for (final p in profilesRes as List) p['id'] as String: p,
    };

    return list.map((e) {
      final profile =
          profileMap[e['requester_id'] as String] as Map<String, dynamic>?;
      return FriendRequestModel.fromJson({
        ...e,
        'profiles': profile ?? {},
      });
    }).toList();
  }

  /// 보낸 친구 요청 (대기 중 — 상대가 수락하면 친구됨)
  Future<List<SentRequestModel>> fetchSentPendingRequests() async {
    if (_myId.isEmpty) return [];
    final res = await supabase
        .from('friendships')
        .select('id, receiver_id, created_at')
        .eq('requester_id', _myId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    final list = res as List;
    if (list.isEmpty) return [];

    final receiverIds =
        list.map((e) => e['receiver_id'] as String).toSet().toList();
    final profilesRes = await supabase
        .from('profiles')
        .select('id, nickname, friend_code, avatar_url')
        .inFilter('id', receiverIds);
    final profileMap = {
      for (final p in profilesRes as List) p['id'] as String: p,
    };

    return list.map((e) {
      final profile = profileMap[e['receiver_id'] as String] as Map<String, dynamic>?;
      return SentRequestModel.fromJson({
        ...e,
        'profile': profile ?? {},
      });
    }).toList();
  }

  /// 보낸 요청 취소
  Future<void> cancelSentRequest(int friendshipId) async {
    await supabase
        .from('friendships')
        .delete()
        .eq('id', friendshipId)
        .eq('requester_id', _myId);
  }

  Future<int> fetchPendingRequestCount() async {
    if (_myId.isEmpty) return 0;
    final List<dynamic> res = await supabase
        .from('friendships')
        .select('id')
        .eq('receiver_id', _myId)
        .eq('status', 'pending');
    return res.length;
  }

  Future<List<ProfileModel>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final res = await supabase
        .from('profiles')
        .select()
        .or('nickname.ilike.%$query%,friend_code.ilike.%$query%')
        .neq('id', _myId)
        .limit(20);
    return (res as List).map((e) => ProfileModel.fromJson(e)).toList();
  }

  /// 친구 코드(닉네임#1234)로 정확히 한 명 찾기
  Future<ProfileModel?> findUserByCode(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return null;
    final res = await supabase
        .from('profiles')
        .select()
        .eq('friend_code', trimmed)
        .neq('id', _myId)
        .maybeSingle();
    if (res == null) return null;
    return ProfileModel.fromJson(res);
  }

  Future<void> sendFriendRequest(String receiverId) async {
    await supabase.from('friendships').insert({
      'requester_id': _myId,
      'receiver_id': receiverId,
      'status': 'pending',
    });
  }

  Future<String?> getFriendshipStatus(String targetId) async {
    final res = await supabase
        .from('friendships')
        .select('status')
        .or(
          'and(requester_id.eq.$_myId,receiver_id.eq.$targetId),'
          'and(requester_id.eq.$targetId,receiver_id.eq.$_myId)',
        )
        .maybeSingle();
    return res?['status'] as String?;
  }

  Future<void> acceptFriendRequest(int friendshipId) async {
    await supabase
        .from('friendships')
        .update({'status': 'accepted'})
        .eq('id', friendshipId)
        .eq('receiver_id', _myId);
  }

  Future<void> rejectFriendRequest(int friendshipId) async {
    await supabase
        .from('friendships')
        .delete()
        .eq('id', friendshipId)
        .eq('receiver_id', _myId);
  }

  Future<void> removeFriend(int friendshipId) async {
    await supabase.from('friendships').delete().eq('id', friendshipId);
  }

  Future<String> getOrCreateInviteToken() async {
    if (_myId.isEmpty) throw Exception('로그인이 필요합니다.');
    debugPrint('[FriendRepository] getOrCreateInviteToken start');
    final existing = await supabase
        .from('invite_tokens')
        .select('token')
        .eq('user_id', _myId)
        .isFilter('used_at', null)
        .maybeSingle();

    if (existing != null) {
      debugPrint(
          '[FriendRepository] reuse existing invite token=${existing['token']}');
      return existing['token'] as String;
    }

    final res = await supabase
        .from('invite_tokens')
        .insert({'user_id': _myId})
        .select('token')
        .single();
    debugPrint('[FriendRepository] created new invite token=${res['token']}');
    return res['token'] as String;
  }

  /// 초대용 딥링크 (wishdrop://friend?token=...)
  Future<String> getInviteDeeplink() async {
    final token = await getOrCreateInviteToken();
    return 'wishdrop://friend?token=$token';
  }

  /// 공유용 초대 URL. INVITE_LINK_BASE_URL 설정 시 https 링크(파란 링크) 반환.
  Future<String> getInviteShareUrl() async {
    final token = await getOrCreateInviteToken();
    final base = AppConfig.inviteLinkBaseUrl;
    if (base.isNotEmpty) return '$base?token=$token';
    return 'wishdrop://friend?token=$token';
  }

  Future<ProfileModel?> fetchProfileByToken(String token) async {
    final tokenData = await supabase
        .from('invite_tokens')
        .select('user_id')
        .eq('token', token)
        .maybeSingle();
    if (tokenData == null) return null;

    final inviterId = tokenData['user_id'] as String;
    if (inviterId == _myId) return null;

    final profile = await supabase
        .from('profiles')
        .select()
        .eq('id', inviterId)
        .maybeSingle();
    if (profile == null) return null;
    return ProfileModel.fromJson(profile);
  }

  Future<void> sendRequestByToken(String token, String receiverId) async {
    await sendFriendRequest(receiverId);
    await supabase
        .from('invite_tokens')
        .update({'used_at': DateTime.now().toUtc().toIso8601String()})
        .eq('token', token);
  }
}

