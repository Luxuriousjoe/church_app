import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/media_provider.dart';
import '../models/models.dart';
import '../widgets/media_tile.dart';
import '../widgets/shimmer_loader.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(mediaProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final authState  = ref.watch(authProvider);
    final mediaState = ref.watch(mediaProvider);
    final user       = authState.user;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.surfaceCard,
        onRefresh: () => ref.read(mediaProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(user),
            _buildGreetingSection(user),
            _buildCategoryChips(),
            _buildFeaturedMedia(mediaState),
            _buildRecentSection(mediaState),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(UserModel? user) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      snap: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent.withOpacity(0.4), width: 1),
            ),
            child: const Center(
              child: Icon(Icons.add, color: AppColors.accent, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          Text(AppConstants.appName.toUpperCase(), style: AppTextStyles.labelGold.copyWith(fontSize: 14, letterSpacing: 3)),
        ],
      ),
      actions: [
        if (user != null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => context.go('/settings'),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surfaceCard,
                child: Text(
                  user.name[0].toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGreetingSection(UserModel? user) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    final name = user?.name.split(' ').first ?? 'Beloved';

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greeting, style: AppTextStyles.bodyMedium)
              .animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0),
            const SizedBox(height: 4),
            Text(name, style: AppTextStyles.displayMedium.copyWith(fontSize: 28))
              .animate(delay: 100.ms).fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0),
            const SizedBox(height: 8),
            // Gold divider line
            Container(
              width: 48,
              height: 2,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: AppColors.goldGradient),
              ),
            ).animate(delay: 200.ms).scaleX(begin: 0, end: 1, alignment: Alignment.centerLeft),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = [
      {'label': 'All',     'type': null},
      {'label': 'Videos',  'type': AppConstants.typeVideo},
      {'label': 'Photos',  'type': AppConstants.typePhoto},
      {'label': 'Sermons', 'type': AppConstants.typeAudio},
    ];

    final filter = ref.watch(mediaFilterProvider);

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: categories.length,
          itemBuilder: (_, i) {
            final cat = categories[i];
            final isSelected = filter.type == cat['type'];
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () {
                  ref.read(mediaFilterProvider.notifier).state =
                    MediaFilter(type: cat['type']);
                  ref.read(mediaProvider.notifier).applyFilter(
                    MediaFilter(type: cat['type']),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: isSelected
                      ? const LinearGradient(colors: AppColors.goldGradient)
                      : null,
                    color: isSelected ? null : AppColors.surfaceCard,
                    border: Border.all(
                      color: isSelected ? Colors.transparent : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    cat['label'] as String,
                    style: TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
              )
                .animate(delay: (i * 80).ms)
                .fadeIn(duration: 400.ms)
                .slideX(begin: 0.3, end: 0),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeaturedMedia(MediaListState mediaState) {
    if (mediaState.isLoading && mediaState.items.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 220,
          margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: const ShimmerLoader(),
        ),
      );
    }

    final featured = mediaState.items.take(5).toList();
    if (featured.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Featured', style: AppTextStyles.titleLarge),
                GestureDetector(
                  onTap: () => context.go('/library'),
                  child: Text('See All', style: AppTextStyles.labelGold),
                ),
              ],
            ),
          )
            .animate(delay: 300.ms).fadeIn(duration: 500.ms),

          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: featured.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () => context.go('/media/${featured[i].id}'),
                  child: FeaturedCard(media: featured[i])
                    .animate(delay: (300 + i * 100).ms)
                    .fadeIn(duration: 500.ms)
                    .slideX(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSection(MediaListState mediaState) {
    if (mediaState.isLoading && mediaState.items.isEmpty) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            child: ShimmerListTile(),
          ),
          childCount: 4,
        ),
      );
    }

    if (mediaState.items.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Text('Recent Media', style: AppTextStyles.titleLarge)
                .animate(delay: 400.ms).fadeIn(duration: 500.ms),
            );
          }

          final index = i - 1;
          if (index >= mediaState.items.length) {
            return mediaState.hasMore
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2)),
                )
              : const SizedBox.shrink();
          }

          final media = mediaState.items[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            child: GestureDetector(
              onTap: () => context.go('/media/${media.id}'),
              child: MediaListTile(media: media)
                .animate(delay: (400 + index * 60).ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
            ),
          );
        },
        childCount: mediaState.items.length + 2, // +1 for header, +1 for loader
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 60),
      child: Column(
        children: [
          const Icon(Icons.church_outlined, color: AppColors.textMuted, size: 64),
          const SizedBox(height: 16),
          Text(
            'No media yet',
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Media captured during services will appear here.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      )
        .animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }
}

// ─── Featured Card Widget ────────────────────────────────────────────────────
class FeaturedCard extends StatelessWidget {
  final MediaModel media;
  const FeaturedCard({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Thumbnail / placeholder
            if (media.thumbnailUrl != null)
              Image.network(
                media.thumbnailUrl!,
                width: 260,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
              )
            else
              _buildPlaceholder(),

            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  ),
                ),
              ),
            ),

            // Type badge
            Positioned(
              top: 12,
              right: 12,
              child: _buildTypeBadge(),
            ),

            // Title
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (media.metadata?.eventName != null)
                      Text(
                        media.metadata!.eventName!,
                        style: AppTextStyles.titleMedium.copyWith(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (media.metadata?.speakerName != null)
                      Text(
                        media.metadata!.speakerName!,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    final IconData icon = media.isVideo
      ? Icons.play_circle_outline
      : media.isAudio
        ? Icons.music_note_outlined
        : Icons.image_outlined;

    return Container(
      width: 260,
      height: 200,
      color: AppColors.surfaceLight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.accent, size: 48),
          const SizedBox(height: 8),
          Text(media.type.toUpperCase(), style: AppTextStyles.labelGold.copyWith(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildTypeBadge() {
    final label = media.type.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Lato',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
