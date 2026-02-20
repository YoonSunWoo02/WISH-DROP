import 'package:shared_preferences/shared_preferences.dart';

/// 기기 로컬에 검색 기록 저장 (DB 미사용). 키별로 최근 N개 유지, 개별 삭제 지원.
class SearchHistoryHelper {
  SearchHistoryHelper({required this.storageKey, this.maxItems = 10});

  final String storageKey;
  final int maxItems;

  Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(storageKey);
    return list?.where((s) => s.isNotEmpty).toList() ?? [];
  }

  Future<void> add(String term) async {
    final t = term.trim();
    if (t.isEmpty) return;
    final list = await load();
    final updated = [t, ...list.where((s) => s.toLowerCase() != t.toLowerCase())];
    await _save(updated.take(maxItems).toList());
  }

  Future<void> remove(String term) async {
    final list = await load();
    final t = term.trim();
    await _save(list.where((s) => s != t).toList());
  }

  Future<void> clear() async {
    await _save([]);
  }

  Future<void> _save(List<String> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(storageKey, list);
  }
}
