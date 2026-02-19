// 실제 DB 스키마 기준 (creator_id, end_date, status, thumbnail_url 등)

class ProjectModel {
  final int id;
  final String creatorId;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final int targetAmount;
  final int currentAmount;
  final String status; // 'active' | 'completed' | 'deleted'
  final DateTime? endDate;
  final bool allowAnonymous;
  final bool allowMessages;
  final String? welcomeMessage;
  final String? userId;
  final DateTime createdAt;

  const ProjectModel({
    required this.id,
    required this.creatorId,
    required this.title,
    this.description,
    this.thumbnailUrl,
    required this.targetAmount,
    required this.currentAmount,
    required this.status,
    this.endDate,
    required this.allowAnonymous,
    required this.allowMessages,
    this.welcomeMessage,
    this.userId,
    required this.createdAt,
  });

  // ── 계산 프로퍼티 ───────────────────────────────────────

  double get progressRate =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  /// 기존 코드 호환용 (progressRate와 동일)
  double get progress => progressRate;

  bool get isCompleted => status == 'completed';
  bool get isActive => status == 'active';
  bool get isDeleted => status == 'deleted';

  bool get isExpired =>
      endDate != null && endDate!.isBefore(DateTime.now());

  int? get daysLeft {
    if (endDate == null) return null;
    final diff = endDate!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// 종료 원인 구분
  bool get isCompletedByGoal => isCompleted && currentAmount >= targetAmount;
  bool get isCompletedByExpiry => isCompleted && !isCompletedByGoal;

  // ── JSON 변환 ───────────────────────────────────────────

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as int,
      creatorId: (json['creator_id'] ?? '').toString(),
      title: (json['title'] ?? '') as String,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      targetAmount: (json['target_amount'] ?? 0) as int,
      currentAmount: (json['current_amount'] ?? 0) as int,
      status: (json['status'] ?? 'active') as String,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      allowAnonymous: json['allow_anonymous'] as bool? ?? false,
      allowMessages: json['allow_messages'] as bool? ?? false,
      welcomeMessage: json['welcome_message'] as String?,
      userId: json['user_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'creator_id': creatorId,
        'title': title,
        if (description != null) 'description': description,
        if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
        'target_amount': targetAmount,
        'current_amount': currentAmount,
        'status': status,
        if (endDate != null) 'end_date': endDate!.toUtc().toIso8601String(),
        'allow_anonymous': allowAnonymous,
        'allow_messages': allowMessages,
        if (welcomeMessage != null) 'welcome_message': welcomeMessage,
        if (userId != null) 'user_id': userId,
        'created_at': createdAt.toIso8601String(),
      };
}
