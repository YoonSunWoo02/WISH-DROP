import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wish_drop/features/pages/login_page.dart'; // import 추가
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. .env 파일을 로드합니다.
  await dotenv.load(fileName: ".env");

  // 2. dotenv.env['키이름']을 사용하여 수파베이스를 초기화합니다.
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wish Drop',
      theme: ThemeData(useMaterial3: true),
      home: const LoginPage(), // 로그인 페이지 연결
    );
  }
}
