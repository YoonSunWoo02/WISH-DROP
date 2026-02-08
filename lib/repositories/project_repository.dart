import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // 1. 위시 생성하기 (Create)
  Future<void> createWish({
    required String title,
    required String description,
    required int targetAmount,
    required DateTime endDate,
    required File? imageFile,
    required bool allowAnonymous,
    required bool allowMessages,
    String? welcomeMessage,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception("로그인이 필요합니다.");

    String? imageUrl;

    // 이미지 업로드 로직도 여기서 처리
    if (imageFile != null) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId.jpg';
      await _client.storage
          .from('wish_images')
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
      imageUrl = _client.storage.from('wish_images').getPublicUrl(fileName);
    }

    // DB Insert
    await _client.from('projects').insert({
      'title': title,
      'description': description,
      'target_amount': targetAmount,
      'current_amount': 0,
      'end_date': endDate.toIso8601String(),
      'thumbnail_url': imageUrl,
      'creator_id': userId, // DB 컬럼명에 맞춤
      'allow_anonymous': allowAnonymous,
      'allow_messages': allowMessages, // DB 컬럼명에 맞춤
      'welcome_message': welcomeMessage,
      'status': 'active',
    });
  }

  // 2. 위시 리스트 가져오기 (Read - Stream)
  Stream<List<Map<String, dynamic>>> getProjectStream() {
    return _client
        .from('projects')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }
}
