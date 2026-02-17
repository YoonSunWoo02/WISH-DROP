import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'project_model.dart';

class ProjectRepository {
  final _supabase = Supabase.instance.client;

  Stream<List<ProjectModel>> watchProjects() {
    return _supabase
        .from('projects')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (data) => data.map((json) => ProjectModel.fromJson(json)).toList(),
        );
  }

  // 1. 모든 프로젝트 가져오기 (기존 유지)
  Future<List<ProjectModel>> getProjects() async {
    try {
      final response = await _supabase
          .from('projects')
          .select()
          .order('created_at', ascending: false);
      final List<dynamic> data = response;
      return data.map((json) => ProjectModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('프로젝트 로딩 에러: $e');
      return [];
    }
  }

  // 2. 🚀 [수정됨] 새로운 위시 생성 및 이미지 업로드
  Future<void> createWish({
    required String title,
    required String description,
    required int targetAmount,
    required DateTime endDate,
    required XFile? imageFile,
    required bool allowAnonymous,
    required bool allowMessages,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    // 🚨 여기를 'wish_images'로 정확히 수정!
    const String bucketName = 'wish_images';

    try {
      String? imageUrl;

      if (imageFile != null) {
        final fileExt = imageFile.path.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        final filePath = '${user.id}/$fileName';

        if (kIsWeb) {
          final bytes = await imageFile.readAsBytes();
          await _supabase.storage
              .from(bucketName) // 변수 사용
              .uploadBinary(filePath, bytes);
        } else {
          final file = File(imageFile.path);
          await _supabase.storage
              .from(bucketName) // 변수 사용
              .upload(filePath, file);
        }

        imageUrl = _supabase.storage
            .from(bucketName) // 변수 사용
            .getPublicUrl(filePath);
      }

      // DB 저장 (이전과 동일)
      await _supabase.from('projects').insert({
        'creator_id': user.id, // 🚨 'user_id'가 아니라 에러 메시지에 나온 'creator_id'로 수정!
        'title': title,
        'description': description,
        'target_amount': targetAmount,
        'current_amount': 0,
        'thumbnail_url': imageUrl,
        'end_date': endDate.toIso8601String(),
        'allow_anonymous': allowAnonymous,
        'allow_messages': allowMessages,
      });

      debugPrint("위시 생성 성공!");
    } catch (e) {
      debugPrint('위시 생성 에러: $e');
      throw Exception('위시 생성 실패: $e');
    }
  }

  Future<List<ProjectModel>> getMyWishes() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('projects')
          .select()
          .eq('user_id', user.id) // 내 아이디와 일치하는 것만!
          .order('created_at', ascending: false);

      final List<dynamic> data = response;
      return data.map((json) => ProjectModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('내 위시 로딩 에러: $e');
      return [];
    }
  }
}
