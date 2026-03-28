import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';
import '../providers/media_provider.dart';
import '../models/models.dart';
import '../widgets/shimmer_loader.dart';

class MediaLibraryScreen extends ConsumerStatefulWidget {
  const MediaLibraryScreen({super.key});
  @override
  ConsumerState<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends ConsumerState<MediaLibraryScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = '';
  bool _isSearching = false;

  static const _tabs = [
    {'label': 'All',     'type': null},
    {'label': 'Videos',  'type': AppConstants.typeVideo},
    {'label': 'Photos',  'type': AppConstants.typePhoto},
    {'label': 'Audio',   'type': AppConstants.typeAudio},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      final type = _tabs[_tabController.index]['type'];
      ref.read(mediaProvider.notifier).applyFilter(
        MediaFilter(type: type, search: _searchQuery.isNotEmpty ? _searchQuery : null),
      );
    });
    Future.microtask(() => ref.read(mediaProvider.notifier).refresh());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmit(String query) {
    setState(() => _searchQuery = query);
    final type = _tabs[_tabController.index]['type'];
    ref.read(mediaProvider.notifier).applyFilter(
      MediaFilter(type: type, search: query.isNotEmpty ? query : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaState = ref.watch(mediaProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: AppColors.primary,
            title: _isSearching ? _buildSearchField() : const Text('Media Library'),
            titleTextStyle: AppTextStyles.titleLarge,
            actions: [
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search, color: AppColors.textPrimary),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      _onSearchSubmit('');
                    }
                  });
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accent,
              indicatorWeight: 2,
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5),
              unselectedLabelStyle: const TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.w400, fontSize: 13),
              tabs: _tabs.map((t) => Tab(text: t['label'] as String)).toList(),
            ),
          ),
        ],
        body: _buildGrid(mediaState),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      style: AppTextStyles.bodyLarge,
      cursorColor: AppColors.accent,
      decoration: const InputDecoration(
        hintText: 'Search sermons, events...',
        hintStyle: TextStyle(color: AppColors.textMuted, fontFamily: 'Lato'),
        border: InputBorder.none,
        filled: false,
      ),
      onSubmitted: _onSearchSubmit,
      onChanged: (v) {
        if (v.isEmpty) _onSearchSubmit('');
      },
    );
  }

  Widget _buildGrid(MediaListState mediaState) {
    if (mediaState.isLoading && mediaState.items.isEmpty) {
      return _buildShimmerGrid();
    }

    if (mediaState.items.isEmpty) {
      return _buildEmptyState();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
          ref.read(mediaProvider.notifier).loadMedia();
        }
        return false;
      },
      child: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.surfaceCard,
        onRefresh: () => ref.read(mediaProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverMasonryGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childCount: mediaState.items.length,
                itemBuilder: (context, index) {
                  final media = mediaState.items[index];
                  return GestureDetector(
                    onTap: () => context.go('/media/${media.id}'),
                    child: _GridCard(media: media)
                      .animate(delay: (index * 40).ms)
                      .fadeIn(duration: 400.ms)
                      .scale(begin: const Offset(0.92, 0.92), curve: Curves.easeOutBack),
                  );
                },
              ),
            ),
            if (mediaState.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2)),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: 8,
        itemBuilder: (_, i) => Container(
          height: i % 3 == 0 ? 200 : 150,
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const ShimmerLoader(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_library_outlined, color: AppColors.textMuted, size: 64),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No results found' : 'No media available',
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
              ? 'Try a different search term'
              : 'Check back after the next service',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      )
        .animate().fadeIn(duration: 600.ms),
    );
  }
}

// ─── Grid Card ───────────────────────────────────────────────────────────────
class _GridCard extends StatelessWidget {
  final MediaModel media;
  const _GridCard({required this.media});

  @override
  Widget build(BuildContext context) {
    // Vary heights for masonry effect
    final heights = [160.0, 200.0, 140.0, 180.0, 160.0];
    final height = heights[media.id % heights.length];

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail
            if (media.thumbnailUrl != null)
              Image.network(
                media.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            else
              _placeholder(),

            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                  ),
                ),
              ),
            ),

            // Play icon for video
            if (media.isVideo)
              Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.5),
                    border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                ),
              ),

            // Type + title at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _typePill(),
                    const SizedBox(height: 4),
                    Text(
                      media.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Lato',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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

  Widget _placeholder() {
    final icon = media.isVideo
      ? Icons.videocam_outlined
      : media.isAudio
        ? Icons.mic_outlined
        : Icons.image_outlined;
    return Container(
      color: AppColors.surfaceLight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.accent.withOpacity(0.6), size: 36),
        ],
      ),
    );
  }

  Widget _typePill() {
    final color = media.isVideo
      ? AppColors.info
      : media.isAudio
        ? AppColors.success
        : AppColors.accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        media.type.toUpperCase(),
        style: const TextStyle(fontFamily: 'Lato', fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.8),
      ),
    );
  }
}
