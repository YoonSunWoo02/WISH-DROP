import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class DonationRepository {
  final _supabase = Supabase.instance.client;

  /// 결제 검증 플로우용: 후원 INSERT + payment_id (중복 방지)
  Future<void> insertDonation({
    required int projectId,
    required String userId,
    required int amount,
    required String message,
    required bool isAnonymous,
    required String paymentId,
  }) async {
    await _supabase.from('donations').insert({
      'project_id': projectId,
      'user_id': userId,
      'amount': amount,
      'message': message,
      'is_anonymous': isAnonymous,
      'payment_id': paymentId,
    });
  }

  /// current_amount 증가 (트리거가 자동으로 종료 조건 체크)
  Future<void> updateCurrentAmount({
    required int projectId,
    required int addedAmount,
  }) async {
    try {
      // 현재 금액 조회
      final response = await _supabase
          .from('projects')
          .select('current_amount')
          .eq('id', projectId)
          .single();

      final int currentAmount = response['current_amount'] as int;
      final int nextAmount = currentAmount + addedAmount;

      // 금액 업데이트 (트리거가 자동으로 종료 조건 체크)
      await _supabase
          .from('projects')
          .update({'current_amount': nextAmount})
          .eq('id', projectId);
    } catch (e) {
      debugPrint('updateCurrentAmount 에러: $e');
      rethrow;
    }
  }

  Future<void> donate({
    required String projectId,
    required int amount,
    String? message,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    try {
      final int parsedProjectId = int.parse(projectId);

      print("📝 [1단계] 후원 기록 생성 중... Project ID: $parsedProjectId");

      await _supabase.from('donations').insert({
        'project_id': parsedProjectId,
        'user_id': user.id,
        'amount': amount,
        'message': message,
      });

      print("🔍 [2단계] 현재 프로젝트 금액 조회 중...");

      // 현재 금액 조회 (쿼리 형식 수정)
      final project = await _supabase
          .from('projects')
          .select('current_amount')
          .eq('id', parsedProjectId)
          .maybeSingle();

      if (project == null) {
        throw Exception("프로젝트를 찾을 수 없습니다. (ID: $parsedProjectId)");
      }

      final int currentAmount = project['current_amount'] as int? ?? 0;
      final int nextAmount = currentAmount + amount;

      print("🆙 [3단계] 금액 업데이트 중: $currentAmount -> $nextAmount");

      // 금액 업데이트 (트리거가 자동으로 종료 조건 체크)
      final response = await _supabase
          .from('projects')
          .update({'current_amount': nextAmount})
          .eq('id', parsedProjectId)
          .select();

      // 🚨 [핵심] 빈 리스트가 반환되면 권한(RLS) 문제임
      if (response.isEmpty) {
        print("❌ [실패] DB 업데이트 권한이 없습니다. Supabase SQL Editor에서 권한을 풀어주세요.");
        throw Exception("게이지 업데이트 실패 (RLS 정책 문제)");
      }

      print("🚀 [성공] DB 업데이트 및 후원 완료!");
    } catch (e) {
      print("❌ [치명적 에러] 후원 처리 실패: $e");
      rethrow;
    }
  }

  // 2. 내 후원 내역 가져오기
  Future<List<Map<String, dynamic>>> getMyDonations() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('donations')
          .select('*, projects(title)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Fetch Donation Error: $e');
      return [];
    }
  }
}
