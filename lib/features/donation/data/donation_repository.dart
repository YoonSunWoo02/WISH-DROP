import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

class DonationRepository {
  final _supabase = Supabase.instance.client;

  Future<void> donate({
    required String projectId,
    required int amount,
    String? message,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    try {
      // 1. 후원 기록 추가
      await _supabase.from('donations').insert({
        'project_id': projectId,
        'donator_id': user.id, // DB 컬럼명이 donator_id인지 확인 필요
        'amount': amount,
        'message': message,
      });

      // 2. 프로젝트 현재 금액 업데이트
      final projectData = await _supabase
          .from('projects')
          .select('current_amount')
          .eq('id', projectId)
          .single();

      int currentAmount = projectData['current_amount'] ?? 0;

      await _supabase
          .from('projects')
          .update({'current_amount': currentAmount + amount})
          .eq('id', projectId);
    } catch (e) {
      // 에러를 그대로 던져서 UI에서 처리하게 함
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMyDonations() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      // DB 구조상 user_id를 기준으로 필터링하고 projects 테이블의 title을 함께 가져옵니다.
      final response = await _supabase
          .from('donations')
          .select('*, projects(title)')
          .eq('user_id', user.id) // DB 이미지에 user_id라고 되어 있네요!
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('후원 내역 로딩 에러: $e');
      return [];
    }
  }
}
