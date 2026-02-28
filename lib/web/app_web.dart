import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme.dart';
import '../features/friend/presentation/friend_invite_page.dart';
import '../features/friend/presentation/friend_page.dart';
import '../profile/presentation/pages/my_info_page.dart';
import '../features/wish/presentation/pages/create_wish_page.dart';
import 'pages/home_page_web.dart';
import 'pages/login_page_web.dart';
import 'pages/project_detail_page_web.dart';
import 'shell_web.dart';

/// 웹 전용 앱 — URL 기반 라우팅(GoRouter) + 반응형 레이아웃
class AppWeb extends StatelessWidget {
  const AppWeb({super.key});

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
      final isLoginRoute = state.matchedLocation == '/login';
      final isInviteRoute = state.matchedLocation.startsWith('/friend-invite');

      if (!isLoggedIn && !isLoginRoute && !isInviteRoute) {
        return '/login';
      }
      if (isLoggedIn && isLoginRoute) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginPageWeb(),
      ),
      GoRoute(
        path: '/friend-invite',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return FriendInvitePage(token: token);
        },
      ),
      GoRoute(
        path: '/project/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            return const Scaffold(
              body: Center(child: Text('잘못된 링크입니다.')),
            );
          }
          return ProjectDetailPageWeb(projectId: id);
        },
      ),
      GoRoute(
        path: '/create',
        builder: (_, __) => const CreateWishPage(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ShellWeb(
          currentPath: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (_, state) => const NoTransitionPage(
              child: HomePageWeb(),
            ),
          ),
          GoRoute(
            path: '/friend',
            pageBuilder: (_, state) => const NoTransitionPage(
              child: FriendPage(),
            ),
          ),
          GoRoute(
            path: '/my-info',
            pageBuilder: (_, state) => const NoTransitionPage(
              child: MyInfoPage(),
            ),
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Wish Drop',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}
