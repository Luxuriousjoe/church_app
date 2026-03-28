import 'dart:io';
import 'package:workmanager/workmanager.dart';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../utils/secure_storage_helper.dart';

// ─── Workmanager callback (top-level function required) ──────────────────────
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    switch (taskName) {
      case AppConstants.kUploadTask:
        return await BackgroundUploadService._processQueue();
      default:
        return Future.value(true);
    }
  });
}

class BackgroundUploadService {
  // ─── Initialize workmanager ─────────────────────────────────────────────
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

  // ─── Schedule periodic background check ────────────────────────────────
  static Future<void> schedulePeriodicUpload() async {
    await Workmanager().registerPeriodicTask(
      AppConstants.kUploadTask,
      AppConstants.kUploadTask,
      tag:              AppConstants.kUploadTaskTag,
      frequency:        const Duration(minutes: 15),
      constraints:      Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      backoffPolicy:    BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 2),
    );
  }

  // ─── Cancel all tasks ───────────────────────────────────────────────────
  static Future<void> cancelAll() async {
    await Workmanager().cancelByTag(AppConstants.kUploadTaskTag);
  }

  // ─── Process pending uploads ────────────────────────────────────────────
  static Future<bool> _processQueue() async {
    try {
      final token = await SecureStorageHelper.getAccessToken();
      if (token == null) return false;

      final dio = Dio(BaseOptions(
        baseUrl: AppConstants.baseUrl,
        headers: {'Authorization': 'Bearer $token'},
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 5),
      ));

      // Fetch pending media from backend
      final response = await dio.get('/media/admin/queue');
      if (response.statusCode != 200) return false;

      final items = response.data['data'] as List;
      final pendingItems = items.where((item) =>
        item['status'] == 'pending' || item['status'] == 'failed'
      ).toList();

      for (final item in pendingItems) {
        final mediaId = item['id'] as int;
        try {
          await dio.post('/uploads/$mediaId/trigger');
        } catch (e) {
          // Continue with next item
        }
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── One-time immediate upload trigger ──────────────────────────────────
  static Future<void> triggerImmediateUpload(int mediaId) async {
    await Workmanager().registerOneOffTask(
      '${AppConstants.kUploadTask}_$mediaId',
      AppConstants.kUploadTask,
      tag:         AppConstants.kUploadTaskTag,
      inputData:   {'mediaId': mediaId},
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }
}
