import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_config.dart'; // 설정 파일 import
import 'core/theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/wish/presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 환경 설정 로드 (깔끔!)
  await AppConfig.init();

  // 2. Supabase 초기화
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

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
    );
  }
}
