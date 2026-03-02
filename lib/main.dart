import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';
import 'core/app_config.dart';
import 'core/theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/friend/presentation/friend_invite_page.dart';
import 'features/wish/data/project_repository.dart';
import 'features/wish/presentation/pages/home_page.dart';
import 'web/app_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AppConfig.init();
  } catch (e) {
    debugPrint('AppConfig.init 실패: $e');
    if (kIsWeb) {
      runApp(_ErrorApp(message: '.env 로드 실패. 프로젝트 루트에 .env 파일이 있는지 확인하세요.'));
      return;
    }
    rethrow;
  }

  final supabaseUrl = AppConfig.supabaseUrl;
  final supabaseAnonKey = AppConfig.supabaseAnonKey;
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    debugPrint('Supabase 설정 누락: SUPABASE_URL, SUPABASE_ANON_KEY 확인');
    if (kIsWeb) {
      runApp(
        const _ErrorApp(
          message: '.env에 SUPABASE_URL, SUPABASE_ANON_KEY를 설정하세요.',
        ),
      );
      return;
    }
  }

  if (!kIsWeb) {
    KakaoSdk.init(nativeAppKey: AppConfig.kakaoNativeAppKey);
  }

  try {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  } catch (e) {
    debugPrint('Supabase 초기화 실패: $e');
    if (kIsWeb) {
      runApp(_ErrorApp(message: 'Supabase 연결 실패: $e'));
      return;
    }
    rethrow;
  }

  try {
    final repo = ProjectRepository();
    await repo.checkAndCompleteProjects();
  } catch (_) {}

  if (kIsWeb) {
    GoogleFonts.notoSansKr(fontSize: 14);
    GoogleFonts.plusJakartaSans(fontSize: 14);
    await GoogleFonts.pendingFonts();
  }

  runApp(kIsWeb ? const AppWeb() : const MyApp());
}

class _ErrorApp extends StatelessWidget {
  final String message;

  const _ErrorApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wish Drop',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      // 로그인 상태에 따라 첫 화면 결정
      home: Supabase.instance.client.auth.currentUser == null
          ? const LoginPage()
          : const HomePage(),
      routes: {
        '/friend-invite': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final token = args is String ? args : '';
          return FriendInvitePage(token: token);
        },
      },
    );
  }
}
