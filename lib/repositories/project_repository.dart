import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ❌ import 'dart:io'; <-- 절대 사용 금지 (웹 호환성 위해)

class ProjectRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // 1️⃣ [추가된 부분] 홈 화면에서 위시 목록 불러오기 (실시간 연동)
  Stream<List<Map<String, dynamic>>> getProjectStream() {
    return _client
        .from('projects')
        .stream(primaryKey: ['id']) // id를 기준으로 실시간 감시
        .order('created_at', ascending: false); // 최신순 정렬
  }

  // 2️⃣ 위시 만들기 (아까 고친 웹 호환 코드)
  Future<void> createWish({
    required String title,
    required String description,
    required int targetAmount,
    required DateTime endDate,
    required XFile? imageFile,
    required bool allowAnonymous,
    required bool allowMessages,
    String? welcomeMessage,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception("로그인이 필요합니다.");

    String? imageUrl;

    if (imageFile != null) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId.jpg';

      // 웹/앱 호환되는 방식 (Bytes 업로드)
      final imageBytes = await imageFile.readAsBytes();

      await _client.storage
          .from('wish_images')
          .uploadBinary(
            fileName,
            imageBytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      imageUrl = _client.storage.from('wish_images').getPublicUrl(fileName);
    }

    await _client.from('projects').insert({
      'title': title,
      'description': description,
      'target_amount': targetAmount,
      'current_amount': 0,
      'end_date': endDate.toIso8601String(),
      'thumbnail_url': imageUrl,
      'creator_id': userId,
      'allow_anonymous': allowAnonymous,
      'allow_messages': allowMessages,
      'welcome_message': welcomeMessage,
      'status': 'active',
    });
  }
}
