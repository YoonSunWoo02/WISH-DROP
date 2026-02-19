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
        .stream(primaryKey: ['id']) // id를 기준으로 변화 감지
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

  Stream<List<ProjectModel>> getProjectsStream() {
    return _supabase
        .from('projects')
        .stream(primaryKey: ['id']) // id 기준으로 변화 감지
        .order('created_at', ascending: false)
        .map(
          (data) => data.map((json) => ProjectModel.fromJson(json)).toList(),
        );
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

      // DB 저장 (status = 'active', end_date 사용)
      await _supabase.from('projects').insert({
        'creator_id': user.id,
        'title': title,
        'description': description,
        'target_amount': targetAmount,
        'current_amount': 0,
        'status': 'active',
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
          .eq('creator_id', user.id)
          .order('created_at', ascending: false);

      final List<dynamic> data = response;
      return data.map((json) => ProjectModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('내 위시 로딩 에러: $e');
      return [];
    }
  }

  // ── 종료 체크 및 status 기반 조회 (위시 자동 종료 기능) ─────────────────

  /// 기간 만료/금액 달성 위시를 일괄 completed 처리
  Future<void> checkAndCompleteProjects() async {
    try {
      await _supabase.rpc('check_and_complete_projects');
    } catch (e) {
      debugPrint('checkAndCompleteProjects 에러: $e');
    }
  }

  /// 활성 위시만 (홈 피드 등)
  Future<List<ProjectModel>> fetchActiveProjects() async {
    try {
      final res = await _supabase
          .from('projects')
          .select()
          .eq('status', 'active')
          .order('created_at', ascending: false);
      return (res as List).map((e) => ProjectModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('fetchActiveProjects 에러: $e');
      return [];
    }
  }

  /// ID로 단건 조회 (상세 페이지 갱신용)
  Future<ProjectModel?> fetchProjectById(int id) async {
    try {
      final res = await _supabase
          .from('projects')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (res == null) return null;
      return ProjectModel.fromJson(res);
    } catch (e) {
      debugPrint('fetchProjectById 에러: $e');
      return null;
    }
  }

  /// 내 위시 — 진행 중만 (creator_id + status = active)
  Future<List<ProjectModel>> fetchMyActiveProjects(String userId) async {
    try {
      final res = await _supabase
          .from('projects')
          .select()
          .eq('creator_id', userId)
          .eq('status', 'active')
          .order('created_at', ascending: false);
      return (res as List).map((e) => ProjectModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('fetchMyActiveProjects 에러: $e');
      return [];
    }
  }

  /// 내 위시 — 종료됨만 (creator_id + status = completed)
  Future<List<ProjectModel>> fetchMyCompletedProjects(String userId) async {
    try {
      final res = await _supabase
          .from('projects')
          .select()
          .eq('creator_id', userId)
          .eq('status', 'completed')
          .order('created_at', ascending: false);
      return (res as List).map((e) => ProjectModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('fetchMyCompletedProjects 에러: $e');
      return [];
    }
  }

  Future<void> updateStatus(int projectId, String status) async {
    await _supabase
        .from('projects')
        .update({'status': status})
        .eq('id', projectId);
  }
}
