import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../utils/secure_storage_helper.dart';
import '../models/models.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() { _setupDio(); }

  late final Dio _dio;
  bool _isRefreshing = false;

  void _setupDio() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 120),
      headers: {'Content-Type': 'application/json'},
    ));

    // ─── Request Interceptor: Attach token ──────────────────────────────────
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorageHelper.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && !_isRefreshing) {
          _isRefreshing = true;
          try {
            final refreshed = await _refreshToken();
            if (refreshed) {
              final token = await SecureStorageHelper.getAccessToken();
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              final retryResponse = await _dio.fetch(error.requestOptions);
              handler.resolve(retryResponse);
              return;
            }
          } catch (_) {}
          finally { _isRefreshing = false; }
        }
        handler.next(error);
      },
    ));
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await SecureStorageHelper.getRefreshToken();
    if (refreshToken == null) return false;
    final response = await _dio.post('/auth/refresh', data: {'refreshToken': refreshToken});
    if (response.statusCode == 200 && response.data['success'] == true) {
      final data = response.data['data'];
      await SecureStorageHelper.saveTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );
      return true;
    }
    return false;
  }

  // ─── AUTH ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
    return res.data as Map<String, dynamic>;
  }

  Future<void> logout(String? refreshToken) async {
    await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
  }

  Future<UserModel> getMe() async {
    final res = await _dio.get('/auth/me');
    return UserModel.fromJson(res.data['data']);
  }

  // ─── MEDIA ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getMedia({
    String? type,
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (type != null) params['type'] = type;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final res = await _dio.get('/media', queryParameters: params);
    return res.data as Map<String, dynamic>;
  }

  Future<MediaModel> getMediaById(int id) async {
    final res = await _dio.get('/media/$id');
    return MediaModel.fromJson(res.data['data']);
  }

  Future<Map<String, dynamic>> createMedia({
    required String type,
    required String title,
    required String filePath,
    required Map<String, dynamic> metadata,
  }) async {
    final res = await _dio.post('/media', data: {
      'type': type,
      'title': title,
      'file_path': filePath,
      'metadata': metadata,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteMedia(int id) async {
    await _dio.delete('/media/$id');
  }

  Future<List<MediaModel>> getAdminQueue() async {
    final res = await _dio.get('/media/admin/queue');
    final list = res.data['data'] as List;
    return list.map((e) => MediaModel.fromJson(e)).toList();
  }

  // ─── UPLOADS ───────────────────────────────────────────────────────────────
  Future<void> triggerUpload(int mediaId) async {
    await _dio.post('/uploads/$mediaId/trigger');
  }

  Future<void> updateUploadStatus({
    required int mediaId,
    required String platform,
    required String status,
    String? telegramMsgId,
    String? youtubeLink,
    String? youtubeVideoId,
    String? errorMessage,
  }) async {
    await _dio.patch('/uploads/$mediaId/status', data: {
      'platform': platform,
      'upload_status': status,
      if (telegramMsgId != null) 'telegram_msg_id': telegramMsgId,
      if (youtubeLink != null) 'youtube_link': youtubeLink,
      if (youtubeVideoId != null) 'youtube_video_id': youtubeVideoId,
      if (errorMessage != null) 'error_message': errorMessage,
    });
  }

  Future<List<UploadModel>> getUploadQueue() async {
    final res = await _dio.get('/uploads');
    final list = res.data['data'] as List;
    return list.map((e) => UploadModel.fromJson(e)).toList();
  }

  // ─── ADMIN ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getDashboardStats() async {
    final res = await _dio.get('/admin/stats');
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<List<UserModel>> getAllUsers() async {
    final res = await _dio.get('/admin/users');
    final list = res.data['data'] as List;
    return list.map((e) => UserModel.fromJson(e)).toList();
  }

  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    bool isAdmin = false,
  }) async {
    final endpoint = isAdmin ? '/admin/admins' : '/admin/users';
    await _dio.post(endpoint, data: {'name': name, 'email': email, 'password': password});
  }

  Future<void> toggleUser(int userId) async {
    await _dio.patch('/admin/users/$userId/toggle');
  }
}
