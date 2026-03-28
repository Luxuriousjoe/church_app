import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _crossController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _crossController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    // Listen for auth state changes
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) _navigate();
    });
  }

  void _navigate() {
    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.loading) {
      // Wait a bit more
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _navigate();
      });
      return;
    }
    if (authState.status == AuthStatus.authenticated) {
      context.go('/');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _crossController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // ─── Radial glow background ──────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      AppColors.accent.withOpacity(0.08 + _pulseController.value * 0.06),
                      AppColors.primary,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ─── Stars / particles ───────────────────────────────────────────
          ...List.generate(20, (i) => _buildParticle(i)),

          // ─── Center content ──────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cross icon
                _buildCross()
                  .animate()
                  .scale(begin: const Offset(0, 0), duration: 800.ms, curve: Curves.elasticOut)
                  .fadeIn(duration: 600.ms),

                const SizedBox(height: 32),

                // App name
                Text(
                  AppConstants.appName.toUpperCase(),
                  style: AppTextStyles.displayLarge.copyWith(
                    fontSize: 36,
                    letterSpacing: 8,
                  ),
                )
                  .animate(delay: 400.ms)
                  .fadeIn(duration: 800.ms)
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 8),

                // Tagline
                Text(
                  AppConstants.appTagline.toUpperCase(),
                  style: AppTextStyles.labelGold.copyWith(fontSize: 13, letterSpacing: 4),
                )
                  .animate(delay: 700.ms)
                  .fadeIn(duration: 600.ms),

                const SizedBox(height: 60),

                // Loading indicator
                SizedBox(
                  width: 160,
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.divider,
                    color: AppColors.accent,
                    minHeight: 1,
                  ),
                )
                  .animate(delay: 1000.ms)
                  .fadeIn(duration: 500.ms),
              ],
            ),
          ),

          // ─── Bottom verse ─────────────────────────────────────────────────
          Positioned(
            bottom: 48,
            left: 32,
            right: 32,
            child: Text(
              '"Let everything that has breath praise the LORD."  — Psalm 150:6',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                fontStyle: FontStyle.italic,
                letterSpacing: 0.3,
              ),
            )
              .animate(delay: 1200.ms)
              .fadeIn(duration: 800.ms),
          ),
        ],
      ),
    );
  }

  Widget _buildCross() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) {
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.accent.withOpacity(0.2 + _pulseController.value * 0.1),
                Colors.transparent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.3 + _pulseController.value * 0.2),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.add, color: AppColors.accent, size: 60),
          ),
        );
      },
    );
  }

  Widget _buildParticle(int index) {
    final positions = [
      [0.1, 0.1], [0.9, 0.15], [0.05, 0.5], [0.95, 0.45],
      [0.2, 0.85], [0.8, 0.9], [0.15, 0.3], [0.85, 0.25],
      [0.3, 0.95], [0.7, 0.05], [0.4, 0.08], [0.6, 0.92],
      [0.02, 0.7], [0.98, 0.65], [0.25, 0.55], [0.75, 0.5],
      [0.45, 0.02], [0.55, 0.98], [0.12, 0.75], [0.88, 0.8],
    ];

    final pos = positions[index % positions.length];
    final size = (index % 3 + 1) * 1.5;
    final delay = (index * 150).ms;

    return Positioned(
      left: MediaQuery.of(context).size.width * pos[0],
      top: MediaQuery.of(context).size.height * pos[1],
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (_, __) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withOpacity(
                0.2 + (index % 3) * 0.15 + _pulseController.value * 0.3,
              ),
            ),
          );
        },
      )
        .animate(delay: delay)
        .fadeIn(duration: 1000.ms),
    );
  }
}
