// features/repositories/donation_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/data/donation_model.dart';

class DonationRepository {
  final _supabase = Supabase.instance.client;

  // 내 후원 내역 가져오기
  Future<List<DonationModel>> getMyDonations() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      // 🚀 핵심: donations 테이블과 projects 테이블을 합쳐서 가져옵니다.
      // select('*, projects(*)') <-- 이게 Supabase의 강력한 Join 문법입니다.
      final response = await _supabase
          .from('donations')
          .select('*, projects(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false); // 최신순 정렬

      // 가져온 데이터를 모델 리스트로 변환
      final List<dynamic> data = response;
      return data.map((json) => DonationModel.fromJson(json)).toList();
    } catch (e) {
      print('후원 내역 에러: $e');
      throw Exception('후원 내역을 불러오지 못했습니다.');
    }
  }
}
