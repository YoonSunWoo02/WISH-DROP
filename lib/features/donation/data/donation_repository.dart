import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// insertDonationIfNew 결과: 새로 삽입 / 같은 영수증 중복 / 이미 해당 위시에 후원함
enum DonationInsertResult {
  inserted,
  duplicatePaymentId,
  alreadyDonated,
}

class DonationRepository {
  final _supabase = Supabase.instance.client;

  /// 이 위시(project)에 오늘 이미 후원했는지 판단할 때 사용. 해당 user+project의 가장 최근 후원 시각(UTC) 반환.
  Future<DateTime?> getLastDonationAtForProject(String userId, int projectId) async {
    final res = await _supabase
        .from('donations')
        .select('created_at')
        .eq('user_id', userId)
        .eq('project_id', projectId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (res == null) return null;
    final at = res['created_at'];
    if (at == null) return null;
    return DateTime.parse(at.toString()).toUtc();
  }

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

  /// INSERT 시도 결과 반환.
  /// inserted → 새로 삽입됨(updateCurrentAmount 호출 후 성공 화면)
  /// duplicatePaymentId → 같은 영수증으로 이미 처리됨(성공 화면만)
  /// alreadyDonated → 이 위시에 이미 후원함(안내 메시지)
  Future<DonationInsertResult> insertDonationIfNew({
    required int projectId,
    required String userId,
    required int amount,
    required String message,
    required bool isAnonymous,
    required String paymentId,
  }) async {
    try {
      await _supabase.from('donations').insert({
        'project_id': projectId,
        'user_id': userId,
        'amount': amount,
        'message': message,
        'is_anonymous': isAnonymous,
        'payment_id': paymentId,
      });
      return DonationInsertResult.inserted;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('payment_id')) {
        debugPrint('insertDonationIfNew: 이미 결제된 payment_id — 성공으로 간주');
        return DonationInsertResult.duplicatePaymentId;
      }
      if (msg.contains('user_id') ||
          msg.contains('project_id') ||
          msg.contains('one_per_user_project')) {
        debugPrint('insertDonationIfNew: 이미 후원한 위시(레거시)');
        return DonationInsertResult.alreadyDonated;
      }
      if (msg.contains('duplicate') || msg.contains('unique') || msg.contains('23505')) {
        debugPrint('insertDonationIfNew: 중복 — payment_id로 간주');
        return DonationInsertResult.duplicatePaymentId;
      }
      rethrow;
    }
  }

  /// current_amount 원자적 증가 (동시성 안전 — RPC에서 SET current_amount = current_amount + N)
  Future<void> updateCurrentAmount({
    required int projectId,
    required int addedAmount,
  }) async {
    try {
      await _supabase.rpc(
        'increment_project_amount',
        params: {
          'p_project_id': projectId,
          'p_amount': addedAmount,
        },
      );
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
      final parsedProjectId = int.tryParse(projectId);
      if (parsedProjectId == null) {
        throw Exception('잘못된 프로젝트 ID입니다.');
      }

      print("📝 [1단계] 후원 기록 생성 중... Project ID: $parsedProjectId");

      await _supabase.from('donations').insert({
        'project_id': parsedProjectId,
        'user_id': user.id,
        'amount': amount,
        'message': message,
      });

      print("🆙 [2단계] 금액 원자적 증가 (increment_project_amount RPC)");

      await _supabase.rpc(
        'increment_project_amount',
        params: {
          'p_project_id': parsedProjectId,
          'p_amount': amount,
        },
      );

      print("🚀 [성공] 후원 완료!");
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

  /// 내 후원 내역 + 프로젝트 생성자(친구) 닉네임·프사 (월별 리스트용)
  Future<List<Map<String, dynamic>>> getMyDonationsWithCreator() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('donations')
          .select('*, projects(title, creator_id)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(response);
      final creatorIds = <String>{};
      for (final d in list) {
        final p = d['projects'] as Map<String, dynamic>?;
        final id = p?['creator_id'] as String?;
        if (id != null && id.isNotEmpty) creatorIds.add(id);
      }

      if (creatorIds.isEmpty) return list;

      final profilesRes = await _supabase
          .from('profiles')
          .select('id, nickname, avatar_url')
          .inFilter('id', creatorIds.toList());
      final profiles = { for (final x in profilesRes as List) x['id'] as String: x as Map<String, dynamic> };

      for (final d in list) {
        final p = d['projects'] as Map<String, dynamic>?;
        if (p == null) continue;
        final creatorId = p['creator_id'] as String?;
        final profile = creatorId != null ? profiles[creatorId] : null;
        p['creator_nickname'] = profile?['nickname'] as String?;
        p['creator_avatar_url'] = profile?['avatar_url'] as String?;
      }

      return list;
    } catch (e) {
      debugPrint('getMyDonationsWithCreator Error: $e');
      return getMyDonations();
    }
  }
}
