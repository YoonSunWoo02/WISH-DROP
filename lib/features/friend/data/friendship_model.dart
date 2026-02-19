class FriendRequestModel {
  final int id;
  final String requesterId;
  final String requesterNickname;
  final String requesterCode;
  final String? requesterAvatarUrl;
  final DateTime createdAt;

  const FriendRequestModel({
    required this.id,
    required this.requesterId,
    required this.requesterNickname,
    required this.requesterCode,
    this.requesterAvatarUrl,
    required this.createdAt,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>? ?? {};
    return FriendRequestModel(
      id: json['id'] as int,
      requesterId: json['requester_id'] as String,
      requesterNickname: profile['nickname'] as String? ?? '사용자',
      requesterCode: profile['friend_code'] as String? ?? '',
      requesterAvatarUrl: profile['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// 내가 보낸 친구 요청 (대기 중)
class SentRequestModel {
  final int id;
  final String receiverId;
  final String receiverNickname;
  final String receiverCode;
  final String? receiverAvatarUrl;
  final DateTime createdAt;

  const SentRequestModel({
    required this.id,
    required this.receiverId,
    required this.receiverNickname,
    required this.receiverCode,
    this.receiverAvatarUrl,
    required this.createdAt,
  });

  factory SentRequestModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>? ?? {};
    return SentRequestModel(
      id: json['id'] as int,
      receiverId: json['receiver_id'] as String,
      receiverNickname: profile['nickname'] as String? ?? '사용자',
      receiverCode: profile['friend_code'] as String? ?? '',
      receiverAvatarUrl: profile['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class FriendModel {
  final int friendshipId;
  final String friendId;
  final String nickname;
  final String friendCode;
  final String? avatarUrl;
  final int activeWishCount;

  const FriendModel({
    required this.friendshipId,
    required this.friendId,
    required this.nickname,
    required this.friendCode,
    this.avatarUrl,
    required this.activeWishCount,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>;
    return FriendModel(
      friendshipId: json['id'] as int,
      friendId: json['friend_id'] as String,
      nickname: profile['nickname'] as String,
      friendCode: profile['friend_code'] as String,
      avatarUrl: profile['avatar_url'] as String?,
      activeWishCount: json['active_wish_count'] as int? ?? 0,
    );
  }
}

