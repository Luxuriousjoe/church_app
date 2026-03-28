import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Map<String, dynamic>? _stats;
  bool _loadingStats = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final authState = ref.read(authProvider);
    if (!authState.isAdmin) return;
    setState(() => _loadingStats = true);
    try {
      final api = ApiService();
      final stats = await api.getDashboardStats();
      if (mounted) setState(() { _stats = stats; _loadingStats = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isAdmin = authState.isAdmin;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: AppColors.primaryGradient,
                      ),
                    ),
                  ),
                  // Gold circle decoration
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.accent.withOpacity(0.15), width: 30),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.accent.withOpacity(0.2),
                            child: Text(
                              (user?.name ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'Cinzel',
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(user?.name ?? '', style: AppTextStyles.titleLarge),
                                Text(user?.email ?? '', style: AppTextStyles.bodyMedium),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isAdmin ? AppColors.accent.withOpacity(0.2) : AppColors.surfaceLight,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isAdmin ? AppColors.accent.withOpacity(0.4) : AppColors.divider),
                                  ),
                                  child: Text(
                                    isAdmin ? '✦ ADMIN' : 'MEMBER',
                                    style: AppTextStyles.labelGold.copyWith(fontSize: 9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Admin stats
                  if (isAdmin) ...[
                    _buildStatsSection().animate(delay: 100.ms).fadeIn(duration: 500.ms),
                    const SizedBox(height: 24),
                  ],

                  // Sections
                  _buildSection(
                    title: 'Media',
                    items: [
                      if (isAdmin) _SettingsItem(icon: Icons.upload_outlined, label: 'Upload Queue', onTap: () => context.go('/queue')),
                      if (isAdmin) _SettingsItem(icon: Icons.camera_alt_outlined, label: 'Capture Media', onTap: () => context.go('/capture')),
                      _SettingsItem(icon: Icons.photo_library_outlined, label: 'Media Library', onTap: () => context.go('/library')),
                    ],
                    delay: 200,
                  ),

                  const SizedBox(height: 16),

                  if (isAdmin) ...[
                    _buildSection(
                      title: 'Administration',
                      items: [
                        _SettingsItem(icon: Icons.people_outline, label: 'Manage Users', onTap: () => _showUsersSheet(context)),
                        _SettingsItem(icon: Icons.person_add_outlined, label: 'Add Admin User', onTap: () => _showAddUserSheet(context, isAdmin: true)),
                        _SettingsItem(icon: Icons.history_outlined, label: 'Activity Logs', onTap: () => _showLogs(context)),
                      ],
                      delay: 300,
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildSection(
                    title: 'Account',
                    items: [
                      _SettingsItem(icon: Icons.lock_outline, label: 'Change Password', onTap: () => _showChangePassword(context)),
                      _SettingsItem(icon: Icons.info_outline, label: 'App Version', trailing: AppConstants.appVersion),
                    ],
                    delay: 400,
                  ),

                  const SizedBox(height: 24),

                  // Sign out button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.error.withOpacity(0.4)),
                      color: AppColors.error.withOpacity(0.08),
                    ),
                    child: TextButton.icon(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                      label: const Text('Sign Out', style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.w700, color: AppColors.error, letterSpacing: 0.5)),
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ).animate(delay: 500.ms).fadeIn(duration: 500.ms),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_loadingStats) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2));
    }
    if (_stats == null) return const SizedBox.shrink();

    final items = [
      {'label': 'Videos',   'value': _stats!['videos'],  'icon': Icons.videocam_outlined,      'color': AppColors.info},
      {'label': 'Photos',   'value': _stats!['photos'],  'icon': Icons.image_outlined,          'color': AppColors.accent},
      {'label': 'Sermons',  'value': _stats!['audios'],  'icon': Icons.mic_outlined,            'color': AppColors.success},
      {'label': 'Members',  'value': _stats!['total_users'], 'icon': Icons.people_outline,      'color': AppColors.warning},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overview', style: AppTextStyles.titleLarge),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.2,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final item = items[i];
            final color = item['color'] as Color;
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(item['icon'] as IconData, color: color, size: 24),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${item['value'] ?? 0}',
                        style: AppTextStyles.titleLarge.copyWith(color: color, fontFamily: 'Lato', fontSize: 20),
                      ),
                      Text(item['label'] as String, style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required List<_SettingsItem> items, required int delay}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: AppTextStyles.labelGold.copyWith(letterSpacing: 2)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  ListTile(
                    leading: Icon(item.icon, color: AppColors.accent, size: 20),
                    title: Text(item.label, style: AppTextStyles.bodyLarge.copyWith(fontSize: 15)),
                    trailing: item.trailing != null
                      ? Text(item.trailing!, style: AppTextStyles.bodyMedium)
                      : const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                    onTap: item.onTap,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                  if (i < items.length - 1)
                    Divider(indent: 52, endIndent: 16, color: AppColors.divider, height: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    ).animate(delay: delay.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0);
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out', style: AppTextStyles.titleLarge),
        content: const Text('Are you sure you want to sign out?', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted, fontFamily: 'Lato'))),
          TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Sign Out', style: TextStyle(color: AppColors.error, fontFamily: 'Lato', fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  void _showUsersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _UsersSheet(),
    );
  }

  void _showAddUserSheet(BuildContext context, {bool isAdmin = false}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddUserSheet(isAdmin: isAdmin),
    );
  }

  void _showLogs(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs feature coming soon'), backgroundColor: AppColors.info),
    );
  }

  void _showChangePassword(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _ChangePasswordSheet(),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback? onTap;
  const _SettingsItem({required this.icon, required this.label, this.trailing, this.onTap});
}

// ─── Users Sheet ─────────────────────────────────────────────────────────────
class _UsersSheet extends StatefulWidget {
  const _UsersSheet();
  @override
  State<_UsersSheet> createState() => _UsersSheetState();
}

class _UsersSheetState extends State<_UsersSheet> {
  List<UserModel>? _users;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final users = await ApiService().getAllUsers();
      if (mounted) setState(() { _users = users; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text('All Users', style: AppTextStyles.titleLarge),
          const SizedBox(height: 16),
          if (_loading) const CircularProgressIndicator(color: AppColors.accent)
          else if (_users == null) const Text('Failed to load')
          else Expanded(
            child: ListView.builder(
              itemCount: _users!.length,
              itemBuilder: (_, i) {
                final u = _users![i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.surfaceLight,
                    child: Text(u.name[0].toUpperCase(), style: const TextStyle(color: AppColors.accent, fontFamily: 'Cinzel')),
                  ),
                  title: Text(u.name, style: AppTextStyles.bodyLarge.copyWith(fontSize: 14)),
                  subtitle: Text(u.email, style: AppTextStyles.caption),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: u.isAdmin ? AppColors.accent.withOpacity(0.15) : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      u.role.toUpperCase(),
                      style: AppTextStyles.labelGold.copyWith(fontSize: 9, color: u.isAdmin ? AppColors.accent : AppColors.textMuted),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Add User Sheet ───────────────────────────────────────────────────────────
class _AddUserSheet extends StatefulWidget {
  final bool isAdmin;
  const _AddUserSheet({required this.isAdmin});
  @override
  State<_AddUserSheet> createState() => _AddUserSheetState();
}

class _AddUserSheetState extends State<_AddUserSheet> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await ApiService().createUser(
        name: _nameCtrl.text, email: _emailCtrl.text,
        password: _passwordCtrl.text, isAdmin: widget.isAdmin,
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.isAdmin ? 'Admin' : 'User'} created'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text('Add ${widget.isAdmin ? 'Admin' : 'User'}', style: AppTextStyles.titleLarge),
          const SizedBox(height: 20),
          TextField(controller: _nameCtrl,     style: AppTextStyles.bodyLarge, decoration: const InputDecoration(labelText: 'Full Name')),
          const SizedBox(height: 12),
          TextField(controller: _emailCtrl,    style: AppTextStyles.bodyLarge, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 12),
          TextField(controller: _passwordCtrl, style: AppTextStyles.bodyLarge, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : Text('Create ${widget.isAdmin ? 'Admin' : 'User'}'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Change Password Sheet ────────────────────────────────────────────────────
class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();
  @override
  ConsumerState<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl     = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Change Password', style: AppTextStyles.titleLarge),
          const SizedBox(height: 20),
          TextField(controller: _currentCtrl, style: AppTextStyles.bodyLarge, decoration: const InputDecoration(labelText: 'Current Password'), obscureText: true),
          const SizedBox(height: 12),
          TextField(controller: _newCtrl,     style: AppTextStyles.bodyLarge, decoration: const InputDecoration(labelText: 'New Password'), obscureText: true),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : () async {
                setState(() => _loading = true);
                // API call would go here
                await Future.delayed(const Duration(seconds: 1));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password updated'), backgroundColor: AppColors.success),
                );
              },
              child: const Text('Update Password'),
            ),
          ),
        ],
      ),
    );
  }
}
