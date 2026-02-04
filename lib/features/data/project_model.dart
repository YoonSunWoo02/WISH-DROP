class ProjectModel {
  final int id;
  final String title;
  final String description;
  final int targetAmount;
  final int currentAmount;
  final String? thumbnailUrl;
  final DateTime endDate;

  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.targetAmount,
    required this.currentAmount,
    this.thumbnailUrl,
    required this.endDate,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'],
      title: json['title'] ?? '제목 없음',
      description: json['description'] ?? '',
      targetAmount: json['target_amount'] ?? 0,
      currentAmount: json['current_amount'] ?? 0,
      thumbnailUrl: json['thumbnail_url'],
      endDate: DateTime.parse(json['end_date']),
    );
  }

  // 달성률 계산 (0.0 ~ 1.0)
  double get progress {
    if (targetAmount == 0) return 0.0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }
}
