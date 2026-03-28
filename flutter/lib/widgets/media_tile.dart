import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../models/models.dart';

// ─── Media List Tile ─────────────────────────────────────────────────────────
class MediaListTile extends StatelessWidget {
  final MediaModel media;
  const MediaListTile({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: SizedBox(
              width: 80,
              height: 72,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (media.thumbnailUrl != null)
                    Image.network(
                      media.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                    )
                  else
                    _thumbPlaceholder(),
                  // Play icon overlay
                  if (media.isVideo)
                    Center(
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _TypeChip(media.type),
                      const Spacer(),
                      Text(
                        _formatDate(media.createdAt.toIso8601String()),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    media.displayTitle,
                    style: AppTextStyles.bodyLarge.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (media.metadata?.speakerName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      media.metadata!.speakerName!,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Arrow
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _thumbPlaceholder() {
    final icon = media.isVideo ? Icons.videocam_outlined
      : media.isAudio ? Icons.mic_outlined : Icons.image_outlined;
    return Container(
      color: AppColors.surfaceLight,
      child: Icon(icon, color: AppColors.accent.withOpacity(0.5), size: 24),
    );
  }

  String _formatDate(String dateStr) {
    try {
      return DateFormat('MMM d').format(DateTime.parse(dateStr));
    } catch (_) { return ''; }
  }
}

// ─── Type Chip ───────────────────────────────────────────────────────────────
class _TypeChip extends StatelessWidget {
  final String type;
  const _TypeChip(this.type);

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (type) {
      case 'video': color = AppColors.info;    break;
      case 'audio': color = AppColors.success; break;
      default:      color = AppColors.accent;  break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(fontFamily: 'Lato', fontSize: 8, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.8),
      ),
    );
  }
}

// ─── Shimmer Loader ───────────────────────────────────────────────────────────
class ShimmerLoader extends StatelessWidget {
  const ShimmerLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceLight,
      highlightColor: AppColors.divider,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceLight,
      highlightColor: AppColors.divider,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              decoration: const BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 10, width: 80, decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 160, decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  Container(height: 10, width: 100, decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'uploaded':   color = AppColors.success; label = 'Uploaded';  icon = Icons.check_circle_outline; break;
      case 'uploading':  color = AppColors.info;    label = 'Uploading'; icon = Icons.sync_outlined;        break;
      case 'failed':     color = AppColors.error;   label = 'Failed';    icon = Icons.error_outline;        break;
      default:           color = AppColors.warning; label = 'Pending';   icon = Icons.schedule_outlined;    break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          Text(label, style: TextStyle(fontFamily: 'Lato', fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// ─── Gold Divider ─────────────────────────────────────────────────────────────
class GoldDivider extends StatelessWidget {
  final double width;
  const GoldDivider({super.key, this.width = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 2,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: AppColors.goldGradient),
      ),
    );
  }
}
