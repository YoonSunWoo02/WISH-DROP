import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';
import 'core/app_config.dart';
import 'core/theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/wish/presentation/pages/home_page.dart';
import 'features/wish/data/project_repository.dart';
import 'features/friend/presentation/friend_invite_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppConfig.init();

  KakaoSdk.init(nativeAppKey: AppConfig.kakaoNativeAppKey);

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  // 앱 실행 시 end_date 만료 위시 일괄 종료
  try {
    final repo = ProjectRepository();
    await repo.checkAndCompleteProjects();
  } catch (_) {}

  runApp(const MyApp());
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
          final token =
              ModalRoute.of(context)!.settings.arguments as String? ?? '';
          return FriendInvitePage(token: token);
        },
      },
    );
  }
}
