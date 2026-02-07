import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // .env 사용을 위해 추가
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wish_drop/core/theme.dart';
import 'package:wish_drop/features/pages/home_page.dart';
import 'package:wish_drop/features/pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. .env 파일 로드
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Env load failed: $e");
  }

  // 2. Supabase 초기화 (PKCE 흐름 적용)
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
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,

      // 한국어 지원 설정
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR')],

      // ✨ 초기 화면을 'AuthGate'로 설정하여 로그인 여부 판단
      home: const AuthGate(),
    );
  }
}

// 🚪 로그인 상태를 확인하는 문지기 위젯
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  // 세션 확인 후 페이지 이동
  Future<void> _checkSession() async {
    // 아주 짧은 딜레이를 주어 스플래시 화면처럼 보이게 함 (선택 사항)
    await Future.delayed(Duration.zero);

    // 1. 현재 세션 가져오기
    final session = Supabase.instance.client.auth.currentSession;

    if (!mounted) return;

    // 2. 세션 유무에 따라 이동
    if (session != null) {
      // ✅ 로그인 됨 -> 홈 페이지로 이동 (뒤로가기 방지)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      // ❌ 로그인 안됨 -> 로그인 페이지로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 세션을 확인하는 동안 보여줄 로딩 화면 (흰 배경에 로딩바)
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
    );
  }
}
