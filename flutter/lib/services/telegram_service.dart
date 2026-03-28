import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../utils/secure_storage_helper.dart';
import '../models/models.dart';

/// Flutter-side Telegram service.
/// Delegates actual sending to the backend (which has the bot token).
/// This service calls the backend trigger endpoint.
class TelegramService {
  final Dio _dio;

  TelegramService()
      : _dio = Dio(BaseOptions(
          baseUrl: AppConstants.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 5),
        ));

  Future<void> _attachToken() async {
    final token = await SecureStorageHelper.getAccessToken();
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  /// Triggers backend to send a media item to the Telegram channel.
  Future<void> sendMedia(int mediaId) async {
    await _attachToken();
    await _dio.post('/uploads/$mediaId/trigger');
  }

  /// Update upload status (called after upload completes).
  Future<void> updateStatus({
    required int mediaId,
    required String platform,
    required String status,
    String? telegramMsgId,
    String? youtubeLink,
    String? errorMessage,
  }) async {
    await _attachToken();
    await _dio.patch('/uploads/$mediaId/status', data: {
      'platform':       platform,
      'upload_status':  status,
      if (telegramMsgId != null) 'telegram_msg_id': telegramMsgId,
      if (youtubeLink   != null) 'youtube_link':    youtubeLink,
      if (errorMessage  != null) 'error_message':   errorMessage,
    });
  }
}
