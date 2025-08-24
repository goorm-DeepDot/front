import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/login_screen.dart';

import '../../features/auth/screens/forgot_account_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/taking/screens/taking_list_screen.dart';
import '../../features/taking/screens/set_taking.dart';
import '../../features/taking/screens/add_complete.dart';

import '../../features/routine/screens/routine_add_complete.dart';
import '../../features/routine/screens/routine_screen.dart';
import '../../features/routine/screens/set_routine.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/home/screens/main_screen.dart';
import '../../features/home/screens/home_screen.dart';

class AppRouter {
  static final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    routes: [
      // 스플래시 화면
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // 온보딩 화면
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // 회원가입 화면
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      
      // 로그인 화면
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // 아이디 찾기 화면
      GoRoute(
        path: '/forgot-id',
        builder: (context, state) => const ForgotAccountScreen(),
      ),

      // 비밀번호 찾기 화면 (통합된 스크린 사용)
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) {
          final tabParam = state.uri.queryParameters['tab'];
          final initialTabIndex = tabParam != null ? int.tryParse(tabParam) ?? 0 : 0;
          return ForgotAccountScreen(initialTabIndex: initialTabIndex);
        },
      ),
      

      // 비밀번호 재설정 화면
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final username = state.uri.queryParameters['username'] ?? '';
          final email = state.uri.queryParameters['email'] ?? '';
          return ResetPasswordScreen(
            username: username,
            email: email,
          );
        },
      ),
      
      // 메인 화면 (탭 네비게이션 포함)
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainScreen(),
      ),
      
      // 복용 이력 리스트
      GoRoute(
        path: '/taking-list',
        builder: (context, state) => const MainScreen(),
      ),

      GoRoute(
        path: '/routine',
        builder: (context, state) => const MainScreen(),
      ),

      GoRoute(
        path: '/settings',
        builder: (context, state) => const MainScreen(),
      ),
      
      // 복용 관련 화면들 (탭바 밖에서 열림)
      GoRoute(
        path: '/taking-add',
        builder: (context, state) => const SetTakingScreen(),
      ),

      // 약 수정 화면 (파라미터 포함)
      GoRoute(
        path: '/taking-edit/:index',
        builder: (context, state) {
          final index = int.parse(state.pathParameters['index'] ?? '0');
          return SetTakingScreen(editIndex: index);
        },
      ),

      GoRoute(
        path: '/taking-complete',
        builder: (context, state) => const TakingAddCompleteScreen(),
      ),

      GoRoute(
        path: '/routine-add',
        builder: (context, state) => const SetRoutineScreen(),
      ),

      GoRoute(
        path: '/set-routine',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return SetRoutineScreen(
            routineName: extra?['routineName'] as String?,
          );
        },
      ),

      GoRoute(
        path: '/routine-add-complete',
        builder: (context, state) => const RoutineAddCompleteScreen(),
      ),
    ],
  );

  static GoRouter get router => _router;
} 