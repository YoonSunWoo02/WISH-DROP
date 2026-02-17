import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class DonationRepository {
  final _supabase = Supabase.instance.client;

  // 1. 후원하기 (DB 업데이트 로직 포함)
  Future<void> donate({
    required String projectId,
    required int amount,
    String? message,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    try {
      // 🚨 ID 타입 확인: DB의 ID가 숫자(int8)라면 int로 변환해서 쿼리해야 합니다.
      final int parsedProjectId = int.parse(projectId);

      // 1. 후원 기록 생성 (이건 RLS가 잘 풀려있어서 성공할 겁니다)
      print("📝 [1단계] 후원 기록 생성 중...");
      await _supabase.from('donations').insert({
        'project_id': parsedProjectId,
        'user_id': user.id,
        'amount': amount,
        'message': message,
      });

      // 2. 프로젝트 현재 금액 가져오기
      print("🔍 [2단계] 현재 프로젝트 금액 조회 중... ID: $parsedProjectId");
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

      // 3. 프로젝트 금액 업데이트
      print("🆙 [3단계] 금액 업데이트 중: $currentAmount -> $nextAmount");
      final response = await _supabase
          .from('projects')
          .update({'current_amount': nextAmount})
          .eq('id', parsedProjectId)
          .select(); // 👈 여기서 [] 가 나오면 여전히 RLS 정책 문제입니다!

      if (response.isEmpty) {
        print("❌ [실패] DB 업데이트 결과가 빈 배열입니다. RLS Policy를 확인하세요.");
        throw Exception("게이지 업데이트 권한이 없습니다. (RLS 정책 확인 필요)");
      }

      print("🚀 [성공] DB 업데이트 완료: $response");
    } catch (e) {
      print("❌ [에러] 후원 처리 실패: $e");
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
