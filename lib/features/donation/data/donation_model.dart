// lib/features/data/donation_model.dart

class DonationModel {
  final int id;
  final int amount;
  final String message;
  final DateTime createdAt;

  // 프로젝트 정보도 같이 담기 (Join 된 데이터)
  final String projectTitle;
  final String? projectThumbnail;

  DonationModel({
    required this.id,
    required this.amount,
    required this.message,
    required this.createdAt,
    required this.projectTitle,
    this.projectThumbnail,
  });

  // Supabase JSON 데이터를 객체로 변환하는 공장
  factory DonationModel.fromJson(Map<String, dynamic> json) {
    // 'projects' 테이블이 연결되어 들어옴 (Supabase Select Query 참고)
    // 데이터가 없을 경우를 대비해 빈 Map({}) 처리
    final project = json['projects'] as Map<String, dynamic>? ?? {};

    return DonationModel(
      id: json['id'],
      amount: json['amount'],
      // 메시지가 null일 수 있으므로 빈 문자열로 처리
      message: json['message'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      // 프로젝트 제목이 없으면 '삭제된 프로젝트' 등으로 표시
      projectTitle: project['title'] ?? '알 수 없는 프로젝트',
      projectThumbnail: project['thumbnail_url'],
    );
  }
}
