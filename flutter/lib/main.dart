import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'constants/app_constants.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/media_library_screen.dart';
import 'screens/media_detail_screen.dart';
import 'screens/capture_screen.dart';
import 'screens/upload_queue_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.primary,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const ProviderScope(child: ChurchMediaApp()));
}

// ─── Router ─────────────────────────────────────────────────────────────────
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter _buildRouter(AuthState authState) => GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  redirect: (context, state) {
    final isSplash = state.matchedLocation == '/splash';
    final isLogin  = state.matchedLocation == '/login';

    if (isSplash) return null;

    if (authState.status == AuthStatus.loading) return '/splash';
    if (authState.status == AuthStatus.unauthenticated && !isLogin) return '/login';
    if (authState.status == AuthStatus.authenticated && isLogin) return '/';

    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login',  builder: (_, __) => const LoginScreen()),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/',        builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/library', builder: (_, __) => const MediaLibraryScreen()),
        GoRoute(path: '/media/:id', builder: (ctx, state) {
          final id = int.parse(state.pathParameters['id']!);
          return MediaDetailScreen(mediaId: id);
        }),
        GoRoute(path: '/capture',  builder: (_, __) => const CaptureScreen()),
        GoRoute(path: '/queue',    builder: (_, __) => const UploadQueueScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      ],
    ),
  ],
);

// ─── App Root ───────────────────────────────────────────────────────────────
class ChurchMediaApp extends ConsumerWidget {
  const ChurchMediaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final router = _buildRouter(authState);

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.theme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
