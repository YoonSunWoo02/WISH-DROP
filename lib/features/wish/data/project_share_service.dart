import 'package:flutter/foundation.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wish_drop/core/app_config.dart';
import 'package:wish_drop/features/wish/data/project_model.dart';

/// 위시(프로젝트) SNS 공유 서비스
/// - share_plus로 기본 공유 (카카오톡, 인스타, 문자 등)
/// - 선택 시 카카오 공유 템플릿 시도 후 실패 시 기본 공유로 폴백
class ProjectShareService {
  static String getProjectShareUrl(int projectId) {
    final base = AppConfig.inviteLinkBaseUrl;
    if (base.isNotEmpty) return '$base/project/$projectId';
    return 'wishdrop://project/$projectId';
  }

  /// 공유 시 DB에 기록 (선택). RPC가 없으면 무시.
  static Future<void> _recordShare(int projectId) async {
    try {
      await Supabase.instance.client.rpc(
        'increment_project_share_count',
        params: {'p_project_id': projectId},
      );
    } catch (e) {
      debugPrint('ProjectShareService: share_count 기록 실패(무시) - $e');
    }
  }

  /// 기본 공유 (share_plus) — 모든 앱에서 동작
  static Future<void> shareWithSystem(ProjectModel project) async {
    final url = getProjectShareUrl(project.id);
    final text = '${project.title}\n${project.description ?? ''}\n\n$url';
    await Share.share(
      text,
      subject: '위시드롭 위시: ${project.title}',
    );
    await _recordShare(project.id);
  }

  /// 카카오 공유 시도 후 실패 시 시스템 공유로 폴백
  static Future<void> shareProject(ProjectModel project) async {
    final url = getProjectShareUrl(project.id);
    final hasKakaoKey = AppConfig.kakaoNativeAppKey.isNotEmpty;

    if (hasKakaoKey) {
      try {
        final imageUri = project.thumbnailUrl != null &&
                project.thumbnailUrl!.isNotEmpty &&
                Uri.tryParse(project.thumbnailUrl!)?.hasAbsolutePath == true
            ? Uri.parse(project.thumbnailUrl!)
            : null;
        final link = Link(
          webUrl: Uri.parse(url),
          mobileWebUrl: Uri.parse(url),
        );
        final template = FeedTemplate(
          content: Content(
            title: project.title,
            description: project.description ?? '한 조각 선물로 응원해 주세요.',
            imageUrl: imageUri,
            link: link,
          ),
          buttons: [
            Button(
              title: '위시 보기',
              link: link,
            ),
          ],
        );
        await ShareClient.instance.shareDefault(template: template);
        await _recordShare(project.id);
        return;
      } catch (e) {
        debugPrint('ProjectShareService: 카카오 공유 실패, 시스템 공유로 진행 - $e');
      }
    }

    await shareWithSystem(project);
  }
}
