import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

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
      // ✅ [수정 1] 문자열 ID를 숫자로 변환 (DB가 int8 타입일 경우 필수)
      final int parsedProjectId = int.parse(projectId);

      print("📝 [1단계] 후원 기록 생성 중... Project ID: $parsedProjectId");

      // ✅ [수정 2] 변환된 parsedProjectId 사용
      await _supabase.from('donations').insert({
        'project_id': parsedProjectId, // projectId (X) -> parsedProjectId (O)
        'user_id': user.id,
        'amount': amount,
        'message': message,
      });

      print("🔍 [2단계] 현재 프로젝트 금액 조회 중...");

      // ✅ [수정 3] 여기서도 parsedProjectId 사용
      final project = await _supabase
          .from('projects')
          .select('current_amount')
          .eq('id', parsedProjectId)
          .maybeSingle();

      if (project == null) {
        throw Exception("프로젝트를 찾을 수 없습니다. (ID: $parsedProjectId)");
      }

      final int currentAmount = project['current_amount'] ?? 0;
      final int nextAmount = currentAmount + amount;

      print("🆙 [3단계] 금액 업데이트 중: $currentAmount -> $nextAmount");

      // ✅ [수정 4] 여기서도 parsedProjectId 사용
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
