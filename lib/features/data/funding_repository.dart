import 'package:supabase_flutter/supabase_flutter.dart';
// 👇 경로가 사용자님 폴더 구조에 맞게 변경되었습니다.
import 'package:wish_drop/features/data/project_model.dart';

class FundingRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ProjectModel>> fetchProjects() async {
    final response = await _supabase
        .from('projects')
        .select()
        .order('created_at', ascending: false);

    final List<dynamic> data = response;
    return data.map((json) => ProjectModel.fromJson(json)).toList();
  }

  Future<void> donate(int projectId, int amount) async {
    await _supabase.rpc(
      'donate_to_project',
      params: {'p_id': projectId, 'amount': amount},
    );
  }
}
