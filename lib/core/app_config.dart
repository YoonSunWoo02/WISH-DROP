import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static Future<void> init() async {
    await dotenv.load(fileName: ".env");
  }

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get kakaoNativeAppKey =>
      dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '';

  /// 친구 초대 링크용 https 주소 (설정 시 메신저에서 파란 링크로 보임)
  /// 예: https://yourdomain.com/invite
  static String get inviteLinkBaseUrl =>
      (dotenv.env['INVITE_LINK_BASE_URL'] ?? '').replaceAll(RegExp(r'/$'), '');
}
