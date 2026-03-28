import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});
  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  static const _routes = ['/', '/library', '/capture', '/queue', '/settings'];

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAdmin = authState.isAdmin;

    return Scaffold(
      backgroundColor: AppColors.primary,
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: _buildBottomNav(isAdmin),
    );
  }

  Widget _buildBottomNav(bool isAdmin) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(index: 0, icon: Icons.home_outlined, activeIcon: Icons.home_rounded,     label: 'Home',    current: _currentIndex, onTap: _onNavTap),
              _NavItem(index: 1, icon: Icons.photo_library_outlined, activeIcon: Icons.photo_library, label: 'Library', current: _currentIndex, onTap: _onNavTap),
              if (isAdmin) ...[
                _CaptureNavItem(index: 2, current: _currentIndex, onTap: _onNavTap),
                _NavItem(index: 3, icon: Icons.upload_outlined, activeIcon: Icons.upload_rounded, label: 'Queue',   current: _currentIndex, onTap: _onNavTap),
              ],
              _NavItem(index: 4, icon: Icons.settings_outlined,  activeIcon: Icons.settings_rounded, label: 'Settings',current: _currentIndex, onTap: _onNavTap),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Standard Nav Item ───────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final int index;
  final int current;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final void Function(int) onTap;

  const _NavItem({
    required this.index, required this.current, required this.icon,
    required this.activeIcon, required this.label, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: isActive ? AppColors.accent : AppColors.textMuted,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AppColors.accent : AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Capture FAB-style Nav Item ──────────────────────────────────────────────
class _CaptureNavItem extends StatelessWidget {
  final int index;
  final int current;
  final void Function(int) onTap;

  const _CaptureNavItem({required this.index, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isActive
              ? AppColors.goldGradient
              : [AppColors.surfaceLight, AppColors.surfaceCard],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(isActive ? 0.5 : 0.2),
              blurRadius: isActive ? 20 : 8,
              spreadRadius: isActive ? 2 : 0,
            ),
          ],
        ),
        child: Icon(
          Icons.camera_alt_rounded,
          color: isActive ? AppColors.primary : AppColors.textSecondary,
          size: 26,
        ),
      ),
    );
  }
}
