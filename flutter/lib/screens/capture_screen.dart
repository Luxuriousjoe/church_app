import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/media_provider.dart';
import '../services/api_service.dart';
import '../models/models.dart';

enum CaptureMode { none, camera, video, audio }

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});
  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen>
    with TickerProviderStateMixin {
  final _picker   = ImagePicker();
  final _recorder = AudioRecorder();
  CaptureMode _mode = CaptureMode.none;
  File? _capturedFile;
  String? _capturedType;
  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;

  // Metadata form
  final _formKey          = GlobalKey<FormState>();
  final _titleCtrl        = TextEditingController();
  final _eventCtrl        = TextEditingController();
  final _speakerCtrl      = TextEditingController();
  final _topicCtrl        = TextEditingController();
  final _descriptionCtrl  = TextEditingController();
  final _locationCtrl     = TextEditingController();
  DateTime? _serviceDate;

  bool _isUploading = false;

  @override
  void dispose() {
    _recorder.dispose();
    _titleCtrl.dispose(); _eventCtrl.dispose(); _speakerCtrl.dispose();
    _topicCtrl.dispose(); _descriptionCtrl.dispose(); _locationCtrl.dispose();
    super.dispose();
  }

  // ─── Capture Actions ──────────────────────────────────────────────────────
  Future<void> _capturePhoto() async {
    final perms = await [Permission.camera].request();
    if (perms[Permission.camera]!.isDenied) return;

    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      maxWidth: 2048,
    );
    if (file == null) return;
    setState(() {
      _capturedFile = File(file.path);
      _capturedType = AppConstants.typePhoto;
      _mode = CaptureMode.camera;
    });
  }

  Future<void> _captureVideo() async {
    final perms = await [Permission.camera, Permission.microphone].request();
    if (perms.values.any((s) => s.isDenied)) return;

    final file = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(hours: 3),
    );
    if (file == null) return;
    setState(() {
      _capturedFile = File(file.path);
      _capturedType = AppConstants.typeVideo;
      _mode = CaptureMode.video;
    });
  }

  Future<void> _startRecording() async {
    final perm = await Permission.microphone.request();
    if (perm.isDenied) return;

    final dir  = await getTemporaryDirectory();
    final path = '${dir.path}/audio_${const Uuid().v4()}.m4a';

    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    setState(() { _isRecording = true; _mode = CaptureMode.audio; });

    // Track duration
    Stream.periodic(const Duration(seconds: 1)).listen((_) {
      if (!_isRecording) return;
      setState(() => _recordDuration += const Duration(seconds: 1));
    });
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    if (path == null) return;
    setState(() {
      _isRecording = false;
      _capturedFile = File(path);
      _capturedType = AppConstants.typeAudio;
    });
  }

  // ─── Upload ───────────────────────────────────────────────────────────────
  Future<void> _upload() async {
    if (_capturedFile == null || !_formKey.currentState!.validate()) return;
    setState(() => _isUploading = true);

    try {
      final api = ApiService();
      final metadata = MediaMetadata(
        eventName:   _eventCtrl.text.trim().isNotEmpty ? _eventCtrl.text.trim() : null,
        speakerName: _speakerCtrl.text.trim().isNotEmpty ? _speakerCtrl.text.trim() : null,
        sermonTopic: _topicCtrl.text.trim().isNotEmpty ? _topicCtrl.text.trim() : null,
        description: _descriptionCtrl.text.trim().isNotEmpty ? _descriptionCtrl.text.trim() : null,
        location:    _locationCtrl.text.trim().isNotEmpty ? _locationCtrl.text.trim() : null,
        serviceDate: _serviceDate?.toIso8601String().substring(0, 10),
      );

      final result = await api.createMedia(
        type: _capturedType!,
        title: _titleCtrl.text.trim(),
        filePath: _capturedFile!.path,
        metadata: metadata.toJson(),
      );

      final mediaId = result['data']['id'] as int;
      await api.triggerUpload(mediaId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Media queued for upload!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _reset();
        context.go('/queue');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _reset() {
    setState(() {
      _capturedFile = null; _capturedType = null;
      _mode = CaptureMode.none; _isRecording = false;
      _recordDuration = Duration.zero;
    });
    _titleCtrl.clear(); _eventCtrl.clear(); _speakerCtrl.clear();
    _topicCtrl.clear(); _descriptionCtrl.clear(); _locationCtrl.clear();
    _serviceDate = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('Capture Media'),
        backgroundColor: AppColors.primary,
        actions: [
          if (_capturedFile != null)
            TextButton(
              onPressed: _reset,
              child: const Text('Reset', style: TextStyle(color: AppColors.accent, fontFamily: 'Lato')),
            ),
        ],
      ),
      body: _capturedFile != null
        ? _buildMetadataForm()
        : _buildCaptureOptions(),
    );
  }

  // ─── Capture Options ──────────────────────────────────────────────────────
  Widget _buildCaptureOptions() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What would you like to capture?', style: AppTextStyles.titleMedium)
            .animate().fadeIn(duration: 500.ms),
          const SizedBox(height: 8),
          Text('Select the type of media to record for this service.', style: AppTextStyles.bodyMedium)
            .animate(delay: 100.ms).fadeIn(duration: 500.ms),

          const SizedBox(height: 40),

          // ─── Three capture buttons ────────────────────────────────────
          Row(
            children: [
              Expanded(child: _CaptureButton(
                icon: Icons.camera_alt_rounded,
                label: 'Photo',
                subtitle: 'Capture moments',
                color: AppColors.accent,
                onTap: _capturePhoto,
                delay: 200,
              )),
              const SizedBox(width: 16),
              Expanded(child: _CaptureButton(
                icon: Icons.videocam_rounded,
                label: 'Video',
                subtitle: 'Record service',
                color: AppColors.info,
                onTap: _captureVideo,
                delay: 300,
              )),
            ],
          ),

          const SizedBox(height: 16),

          // Audio button full width
          _buildAudioButton().animate(delay: 400.ms).fadeIn(duration: 500.ms).slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }

  Widget _buildAudioButton() {
    final isRec = _isRecording;
    return GestureDetector(
      onTap: isRec ? _stopRecording : _startRecording,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isRec ? AppColors.error.withOpacity(0.15) : AppColors.surfaceCard,
          border: Border.all(
            color: isRec ? AppColors.error : AppColors.divider,
            width: isRec ? 1.5 : 1,
          ),
          boxShadow: isRec
            ? [BoxShadow(color: AppColors.error.withOpacity(0.3), blurRadius: 20)]
            : null,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRec ? AppColors.error : AppColors.success.withOpacity(0.15),
                border: Border.all(color: isRec ? AppColors.error : AppColors.success.withOpacity(0.4)),
              ),
              child: Icon(
                isRec ? Icons.stop_rounded : Icons.mic_rounded,
                color: isRec ? Colors.white : AppColors.success,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRec ? 'Recording...' : 'Audio',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: isRec ? AppColors.error : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    isRec
                      ? '${_recordDuration.inMinutes.toString().padLeft(2, '0')}:${(_recordDuration.inSeconds % 60).toString().padLeft(2, '0')}'
                      : 'Record sermon audio',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isRec ? AppColors.error.withOpacity(0.8) : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isRec)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.error),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 500.ms),
          ],
        ),
      ),
    );
  }

  // ─── Metadata Form ────────────────────────────────────────────────────────
  Widget _buildMetadataForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview
          _buildPreview()
            .animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9)),

          const SizedBox(height: 28),

          Text('Media Details', style: AppTextStyles.titleLarge)
            .animate(delay: 100.ms).fadeIn(duration: 500.ms),
          const SizedBox(height: 4),
          Text('Add information about this media.', style: AppTextStyles.bodyMedium)
            .animate(delay: 150.ms).fadeIn(duration: 500.ms),

          const SizedBox(height: 24),

          Form(
            key: _formKey,
            child: Column(
              children: [
                _buildField(_titleCtrl,       'Title',          Icons.title_rounded,          required: true),
                _buildField(_eventCtrl,       'Event / Service Name', Icons.event_rounded),
                _buildField(_speakerCtrl,     'Speaker Name',   Icons.person_outline_rounded),
                _buildField(_topicCtrl,       'Sermon Topic',   Icons.menu_book_outlined),
                _buildField(_locationCtrl,    'Location',       Icons.place_outlined),
                _buildField(_descriptionCtrl, 'Description',    Icons.description_outlined, maxLines: 3),
                const SizedBox(height: 8),
                _buildDatePicker(),
              ]
                .map((w) => Padding(padding: const EdgeInsets.only(bottom: 14), child: w))
                .toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Upload button
          _buildUploadButton()
            .animate(delay: 400.ms).fadeIn(duration: 500.ms).slideY(begin: 0.3, end: 0),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _capturedType == AppConstants.typePhoto
          ? Image.file(_capturedFile!, fit: BoxFit.cover)
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _capturedType == AppConstants.typeVideo ? Icons.videocam_rounded : Icons.mic_rounded,
                    color: AppColors.accent,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _capturedType == AppConstants.typeVideo ? 'Video Captured ✓' : 'Audio Recorded ✓',
                    style: AppTextStyles.titleMedium.copyWith(color: AppColors.accent),
                  ),
                  Text(
                    _capturedFile?.path.split('/').last ?? '',
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      {bool required = false, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
      ),
      validator: required ? (v) => (v == null || v.isEmpty) ? '$label is required' : null : null,
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _serviceDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (ctx, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(primary: AppColors.accent),
            ),
            child: child!,
          ),
        );
        if (date != null) setState(() => _serviceDate = date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: AppColors.textMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _serviceDate != null
                  ? '${_serviceDate!.day}/${_serviceDate!.month}/${_serviceDate!.year}'
                  : 'Service Date (optional)',
                style: _serviceDate != null
                  ? AppTextStyles.bodyLarge
                  : AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: _isUploading ? null : const LinearGradient(colors: AppColors.goldGradient),
        color: _isUploading ? AppColors.surfaceCard : null,
        boxShadow: _isUploading ? null : [
          BoxShadow(color: AppColors.accent.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isUploading ? null : _upload,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isUploading
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)),
                SizedBox(width: 12),
                Text('Uploading...', style: TextStyle(fontFamily: 'Lato', color: AppColors.accent, fontWeight: FontWeight.w700)),
              ],
            )
          : const Text(
              'SAVE & UPLOAD',
              style: TextStyle(fontFamily: 'Lato', fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 2, color: AppColors.primary),
            ),
      ),
    );
  }
}

// ─── Capture Button Widget ───────────────────────────────────────────────────
class _CaptureButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final int delay;

  const _CaptureButton({
    required this.icon, required this.label, required this.subtitle,
    required this.color, required this.onTap, required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.surfaceCard,
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.15),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 14),
            Text(label, style: AppTextStyles.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: AppTextStyles.caption, textAlign: TextAlign.center),
          ],
        ),
      ),
    )
      .animate(delay: delay.ms)
      .fadeIn(duration: 500.ms)
      .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic);
  }
}
