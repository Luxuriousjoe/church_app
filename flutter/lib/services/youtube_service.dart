import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../utils/secure_storage_helper.dart';

/// Handles resumable YouTube uploads directly from the Flutter app.
/// The backend provides a fresh OAuth access token; Flutter does the actual upload.
class YoutubeService {
  final Dio _dio;

  YoutubeService()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 10),
          sendTimeout: const Duration(minutes: 10),
        ));

  // ─── Get OAuth token from backend ──────────────────────────────────────
  Future<String> _getAccessToken() async {
    final token = await SecureStorageHelper.getAccessToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await Dio().get(
      '${AppConstants.baseUrl}/uploads/youtube-token',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data['data']['accessToken'] as String;
  }

  // ─── Upload video via resumable upload ─────────────────────────────────
  Future<Map<String, String>> uploadVideo({
    required File file,
    required String title,
    required String description,
    void Function(int sent, int total)? onProgress,
  }) async {
    final accessToken = await _getAccessToken();
    final fileSize    = await file.length();
    final mimeType    = 'video/mp4';

    // Step 1: Initiate resumable upload session
    final initResponse = await _dio.post(
      'https://www.googleapis.com/upload/youtube/v3/videos?uploadType=resumable&part=snippet,status',
      data: {
        'snippet': {
          'title': title,
          'description': description,
          'tags': ['church', 'sermon', 'worship'],
          'categoryId': '22',
        },
        'status': {'privacyStatus': 'public'},
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'X-Upload-Content-Type': mimeType,
          'X-Upload-Content-Length': fileSize.toString(),
        },
      ),
    );

    final uploadUrl = initResponse.headers['location']?.first;
    if (uploadUrl == null) throw Exception('Failed to get YouTube upload URL');

    // Step 2: Upload the file
    final uploadResponse = await _dio.put(
      uploadUrl,
      data: file.openRead(),
      options: Options(
        headers: {
          'Content-Type': mimeType,
          'Content-Length': fileSize.toString(),
        },
      ),
      onSendProgress: onProgress,
    );

    final videoId = uploadResponse.data['id'] as String?;
    if (videoId == null) throw Exception('YouTube upload failed — no video ID returned');

    return {
      'videoId': videoId,
      'link': 'https://www.youtube.com/watch?v=$videoId',
    };
  }
}
