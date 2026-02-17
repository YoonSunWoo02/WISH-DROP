class ProjectModel {
  final String id;
  final String title;
  final String description;
  final int targetAmount;
  final int currentAmount;
  final String? thumbnailUrl;
  final DateTime endDate;
  final String creatorId; // 👈 이 줄이 있는지 확인하세요!

  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.targetAmount,
    required this.currentAmount,
    this.thumbnailUrl,
    required this.endDate,
    required this.creatorId,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      targetAmount: json['target_amount'] ?? 0,
      currentAmount: json['current_amount'] ?? 0,
      thumbnailUrl: json['thumbnail_url'],
      endDate: DateTime.parse(json['end_date']),
      creatorId: json['creator_id'] ?? '', // 👈 변수명 일치 확인
    );
  }
  // 달성률 계산 (0.0 ~ 1.0)
  double get progress {
    if (targetAmount == 0) return 0.0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }
}
