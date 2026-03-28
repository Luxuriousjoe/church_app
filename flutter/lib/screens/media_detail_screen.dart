import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';
import '../models/models.dart';

// ─── Media Detail Screen ─────────────────────────────────────────────────────
class MediaDetailScreen extends ConsumerStatefulWidget {
  final int mediaId;
  const MediaDetailScreen({super.key, required this.mediaId});
  @override
  ConsumerState<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends ConsumerState<MediaDetailScreen> {
  MediaModel? _media;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMedia();
  }

  Future<void> _fetchMedia() async {
    try {
      final api = ApiService();
      final media = await api.getMediaById(widget.mediaId);
      if (mounted) setState(() { _media = media; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
        : _error != null
          ? _buildError()
          : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          Text('Failed to load media', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _fetchMedia, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final media = _media!;
    return CustomScrollView(
      slivers: [
        // ─── Media Player ──────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: media.isAudio ? 100 : 280,
          pinned: true,
          backgroundColor: AppColors.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary),
              onPressed: _share,
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: media.isVideo
              ? VideoPlayerWidget(media: media)
              : media.isAudio
                ? AudioPlayerWidget(media: media)
                : PhotoViewer(media: media),
          ),
        ),

        // ─── Info Section ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  media.displayTitle,
                  style: AppTextStyles.displayMedium.copyWith(fontSize: 22),
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),

                const SizedBox(height: 8),

                // Metadata pills
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPill(Icons.person_outline, media.metadata?.speakerName ?? 'Church Media', AppColors.accent),
                    if (media.metadata?.serviceDate != null)
                      _buildPill(Icons.calendar_today_outlined, _formatDate(media.metadata!.serviceDate!), AppColors.info),
                    if (media.metadata?.location != null)
                      _buildPill(Icons.place_outlined, media.metadata!.location!, AppColors.success),
                    _buildPill(
                      media.isVideo ? Icons.videocam_outlined : media.isAudio ? Icons.mic_outlined : Icons.image_outlined,
                      media.type.toUpperCase(),
                      AppColors.warning,
                    ),
                  ],
                ).animate(delay: 100.ms).fadeIn(duration: 500.ms),

                const SizedBox(height: 20),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 20),

                // Sermon topic
                if (media.metadata?.sermonTopic != null) ...[
                  _buildInfoRow('📖 Sermon Topic', media.metadata!.sermonTopic!),
                  const SizedBox(height: 12),
                ],

                // Event name
                if (media.metadata?.eventName != null) ...[
                  _buildInfoRow('🎉 Event', media.metadata!.eventName!),
                  const SizedBox(height: 12),
                ],

                // Description
                if (media.metadata?.description != null) ...[
                  Text('About', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 8),
                  Text(media.metadata!.description!, style: AppTextStyles.bodyLarge.copyWith(height: 1.7)),
                  const SizedBox(height: 20),
                ],

                // Links
                if (media.youtubeLink != null)
                  _buildLinkButton(
                    icon: Icons.play_circle_outline,
                    label: 'Watch on YouTube',
                    color: const Color(0xFFFF0000),
                    onTap: () => launchUrl(Uri.parse(media.youtubeLink!)),
                  ).animate(delay: 300.ms).fadeIn(duration: 500.ms).slideY(begin: 0.3),

                if (media.metadata?.participants != null) ...[
                  const SizedBox(height: 20),
                  _buildInfoRow('👥 Participants', media.metadata!.participants!),
                ],

                const SizedBox(height: 32),

                // Posted by
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.surfaceLight,
                      child: Text(
                        (media.uploadedByName ?? 'A')[0].toUpperCase(),
                        style: const TextStyle(fontFamily: 'Cinzel', fontSize: 12, color: AppColors.accent),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Posted by', style: AppTextStyles.caption),
                        Text(
                          media.uploadedByName ?? 'Admin',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(media.createdAt.toIso8601String()),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ).animate(delay: 400.ms).fadeIn(duration: 500.ms),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontFamily: 'Lato', fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
      ],
    );
  }

  Widget _buildLinkButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.w700, color: color, fontSize: 14)),
            const Spacer(),
            Icon(Icons.open_in_new_rounded, color: color.withOpacity(0.7), size: 16),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) { return dateStr; }
  }

  void _share() {
    final media = _media;
    if (media == null) return;
    final text = media.youtubeLink != null
      ? '${media.displayTitle}\n${media.youtubeLink}'
      : media.displayTitle;
    Share.share(text, subject: media.displayTitle);
  }
}

// ─── Video Player Widget ─────────────────────────────────────────────────────
class VideoPlayerWidget extends StatefulWidget {
  final MediaModel media;
  const VideoPlayerWidget({super.key, required this.media});
  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _vpController;
  ChewieController?      _chewieController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final url = widget.media.youtubeLink != null
      ? 'https://www.youtube.com/watch?v=${widget.media.youtubeVideoId}'
      : widget.media.filePath ?? '';

    if (url.isEmpty) return;

    try {
      _vpController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _vpController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _vpController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _vpController!.value.aspectRatio,
        allowFullScreen: true,
        placeholder: Container(color: AppColors.surface),
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.accent,
          bufferedColor: AppColors.surfaceLight,
          backgroundColor: AppColors.divider,
          handleColor: AppColors.accent,
        ),
      );
      if (mounted) setState(() => _initialized = true);
    } catch (_) {}
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _vpController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Container(
        color: AppColors.surface,
        child: const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2)),
      );
    }
    return Chewie(controller: _chewieController!);
  }
}

// ─── Audio Player Widget ─────────────────────────────────────────────────────
class AudioPlayerWidget extends StatefulWidget {
  final MediaModel media;
  const AudioPlayerWidget({super.key, required this.media});
  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget>
    with SingleTickerProviderStateMixin {
  final _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final url = widget.media.filePath ?? '';
    if (url.isEmpty) return;
    try {
      await _player.setUrl(url);
      _player.durationStream.listen((d) {
        if (mounted && d != null) setState(() => _duration = d);
      });
      _player.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _player.playingStream.listen((playing) {
        if (mounted) {
          setState(() => _isPlaying = playing);
          playing ? _waveController.repeat() : _waveController.stop();
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _player.dispose();
    _waveController.dispose();
    super.dispose();
  }

  String _format(Duration d) =>
    '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Waveform / visual
          AnimatedBuilder(
            animation: _waveController,
            builder: (_, __) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(20, (i) {
                final height = _isPlaying
                  ? 8.0 + (20.0 * ((i % 5) / 4.0) * (0.5 + 0.5 * (_waveController.value + i * 0.15).remainder(1.0)))
                  : 4.0;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: 3,
                  height: height.clamp(4.0, 28.0),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(_isPlaying ? 0.9 : 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          // Progress
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: AppColors.divider,
              thumbColor: AppColors.accent,
            ),
            child: Slider(
              value: _duration.inMilliseconds > 0
                ? _position.inMilliseconds / _duration.inMilliseconds
                : 0.0,
              onChanged: (v) {
                final pos = Duration(milliseconds: (_duration.inMilliseconds * v).toInt());
                _player.seek(pos);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_format(_position), style: AppTextStyles.caption),
                Text(_format(_duration), style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Play button
          GestureDetector(
            onTap: () => _isPlaying ? _player.pause() : _player.play(),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: AppColors.goldGradient),
                boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.4), blurRadius: 20)],
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Photo Viewer ────────────────────────────────────────────────────────────
class PhotoViewer extends StatelessWidget {
  final MediaModel media;
  const PhotoViewer({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    final url = media.thumbnailUrl ?? media.filePath;
    if (url == null) {
      return Container(
        color: AppColors.surface,
        child: const Center(child: Icon(Icons.image_outlined, color: AppColors.textMuted, size: 64)),
      );
    }
    return InteractiveViewer(
      child: Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.surface,
          child: const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 48)),
        ),
      ),
    );
  }
}
