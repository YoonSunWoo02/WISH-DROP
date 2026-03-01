import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme.dart';
import '../features/friend/presentation/friend_invite_page.dart';
import '../features/friend/presentation/friend_page.dart';
import '../profile/presentation/pages/my_info_page.dart';
import '../features/auth/presentation/pages/signup_page.dart';
import '../features/wish/data/project_model.dart';
import '../features/wish/presentation/pages/create_wish_page.dart';
import 'pages/donation_page_web.dart';
import 'pages/donation_success_page_web.dart';
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
      final isSignupRoute = state.matchedLocation == '/signup';
      final isInviteRoute = state.matchedLocation.startsWith('/friend-invite');
      final isProjectRoute = state.matchedLocation.startsWith('/project/');

      if (!isLoggedIn &&
          !isLoginRoute &&
          !isSignupRoute &&
          !isInviteRoute &&
          !isProjectRoute) {
        return '/login';
      }
      if (isLoggedIn && isLoginRoute) {
        final redirect = state.uri.queryParameters['redirect'];
        if (redirect != null &&
            redirect.isNotEmpty &&
            redirect.startsWith('/') &&
            !redirect.startsWith('//')) {
          return redirect;
        }
        return '/';
      }
      if (isLoggedIn && isSignupRoute) {
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
        path: '/signup',
        builder: (_, __) => const SignUpPage(),
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
        path: '/donation',
        builder: (context, state) {
          final project = state.extra;
          if (project == null || project is! ProjectModel) {
            return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  onPressed: () => context.go('/'),
                ),
              ),
              body: const Center(
                child: Text(
                  '잘못된 접근입니다. 프로젝트 상세에서 후원을 진행해 주세요.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return DonationPageWeb(project: project);
        },
      ),
      GoRoute(
        path: '/donation-success',
        builder: (context, state) {
          final projectId = int.tryParse(
            state.uri.queryParameters['projectId'] ?? '',
          );
          return DonationSuccessPageWeb(projectId: projectId);
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
