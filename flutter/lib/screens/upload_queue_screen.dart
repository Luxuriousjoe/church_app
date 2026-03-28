import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../providers/media_provider.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class UploadQueueScreen extends ConsumerStatefulWidget {
  const UploadQueueScreen({super.key});
  @override
  ConsumerState<UploadQueueScreen> createState() => _UploadQueueScreenState();
}

class _UploadQueueScreenState extends ConsumerState<UploadQueueScreen> {
  @override
  Widget build(BuildContext context) {
    final queueAsync = ref.watch(uploadQueueProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('Upload Queue'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.accent),
            onPressed: () => ref.refresh(uploadQueueProvider),
          ),
        ],
      ),
      body: queueAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(child: Text('Error: $e', style: AppTextStyles.bodyMedium)),
        data: (queue) => queue.isEmpty
          ? _buildEmpty()
          : _buildQueue(queue),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.upload_outlined, color: AppColors.textMuted, size: 64),
          const SizedBox(height: 16),
          Text('No uploads yet', style: AppTextStyles.titleMedium.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Text('Captured media will appear here.', style: AppTextStyles.bodyMedium),
        ],
      ).animate().fadeIn(duration: 600.ms),
    );
  }

  Widget _buildQueue(List<UploadModel> queue) {
    // Group by media ID
    final grouped = <int, List<UploadModel>>{};
    for (final u in queue) {
      grouped.putIfAbsent(u.mediaId, () => []).add(u);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.length,
      itemBuilder: (_, i) {
        final mediaId = grouped.keys.elementAt(i);
        final uploads = grouped[mediaId]!;
        return _UploadCard(uploads: uploads, mediaId: mediaId)
          .animate(delay: (i * 80).ms)
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.2, end: 0, curve: Curves.easeOut);
      },
    );
  }
}

class _UploadCard extends ConsumerWidget {
  final List<UploadModel> uploads;
  final int mediaId;

  const _UploadCard({required this.uploads, required this.mediaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final first = uploads.first;
    final allSuccess = uploads.every((u) => u.uploadStatus == 'success');
    final anyFailed  = uploads.any((u) => u.uploadStatus == 'failed');
    final anyPending = uploads.any((u) => u.uploadStatus == 'pending' || u.uploadStatus == 'in_progress');

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    if (allSuccess)       { statusColor = AppColors.success; statusIcon = Icons.check_circle_outline; statusLabel = 'Uploaded'; }
    else if (anyFailed)   { statusColor = AppColors.error;   statusIcon = Icons.error_outline;        statusLabel = 'Failed'; }
    else if (anyPending)  { statusColor = AppColors.warning; statusIcon = Icons.schedule_outlined;    statusLabel = 'Pending'; }
    else                  { statusColor = AppColors.info;    statusIcon = Icons.sync_outlined;        statusLabel = 'Processing'; }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    first.mediaType == 'video' ? Icons.videocam_outlined
                      : first.mediaType == 'audio' ? Icons.mic_outlined : Icons.image_outlined,
                    color: AppColors.accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        first.eventName ?? first.mediaTitle ?? 'Media #$mediaId',
                        style: AppTextStyles.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        first.mediaType?.toUpperCase() ?? 'MEDIA',
                        style: AppTextStyles.labelGold.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusLabel, style: TextStyle(fontFamily: 'Lato', fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Platform rows
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: uploads.map((u) => _platformRow(u)).toList(),
            ),
          ),

          // Retry button if failed
          if (anyFailed) ...[
            Divider(color: AppColors.divider, height: 1),
            TextButton.icon(
              onPressed: () => _retryUpload(context, ref, mediaId),
              icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.accent),
              label: const Text('Retry Upload', style: TextStyle(fontFamily: 'Lato', color: AppColors.accent, fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _platformRow(UploadModel upload) {
    Color color;
    IconData icon;

    switch (upload.uploadStatus) {
      case 'success':    color = AppColors.success; icon = Icons.check_circle; break;
      case 'failed':     color = AppColors.error;   icon = Icons.error;        break;
      case 'in_progress': color = AppColors.info;  icon = Icons.sync;         break;
      default:           color = AppColors.textMuted; icon = Icons.schedule;  break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            upload.platform == 'youtube' ? Icons.play_circle_outline : Icons.send_outlined,
            size: 16,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Text(
            upload.platform == 'youtube' ? 'YouTube' : 'Telegram',
            style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
          ),
          const Spacer(),
          if (upload.youtubeLink != null)
            Text(
              upload.youtubeLink!.length > 30
                ? '${upload.youtubeLink!.substring(0, 30)}...'
                : upload.youtubeLink!,
              style: AppTextStyles.caption.copyWith(color: AppColors.info),
            ),
          if (upload.telegramMsgId != null)
            Text('ID: ${upload.telegramMsgId}', style: AppTextStyles.caption),
          const SizedBox(width: 8),
          Icon(icon, size: 14, color: color),
        ],
      ),
    );
  }

  Future<void> _retryUpload(BuildContext context, WidgetRef ref, int mediaId) async {
    try {
      final api = ApiService();
      await api.triggerUpload(mediaId);
      ref.refresh(uploadQueueProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload retry triggered'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Retry failed: $e'), backgroundColor: AppColors.error),
      );
    }
  }
}
