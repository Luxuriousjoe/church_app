import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

// ─── Media Filter State ───────────────────────────────────────────────────
class MediaFilter {
  final String? type;
  final String? search;
  final int page;

  const MediaFilter({this.type, this.search, this.page = 1});

  MediaFilter copyWith({String? type, String? search, int? page, bool clearType = false}) =>
    MediaFilter(
      type:   clearType ? null : (type ?? this.type),
      search: search ?? this.search,
      page:   page ?? this.page,
    );
}

final mediaFilterProvider = StateProvider<MediaFilter>((ref) => const MediaFilter());

// ─── Media List State ─────────────────────────────────────────────────────
class MediaListState {
  final List<MediaModel> items;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int totalCount;

  const MediaListState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.totalCount = 0,
  });

  MediaListState copyWith({
    List<MediaModel>? items,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? totalCount,
  }) => MediaListState(
    items:      items ?? this.items,
    isLoading:  isLoading ?? this.isLoading,
    hasMore:    hasMore ?? this.hasMore,
    error:      error,
    totalCount: totalCount ?? this.totalCount,
  );
}

class MediaNotifier extends StateNotifier<MediaListState> {
  final ApiService _api;
  MediaFilter _currentFilter = const MediaFilter();

  MediaNotifier(this._api) : super(const MediaListState());

  Future<void> loadMedia({bool refresh = false}) async {
    if (state.isLoading) return;
    if (!refresh && !state.hasMore) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _api.getMedia(
        type:   _currentFilter.type,
        search: _currentFilter.search,
        page:   refresh ? 1 : _currentFilter.page,
        limit:  20,
      );

      final newItems = (response['data'] as List)
          .map((e) => MediaModel.fromJson(e))
          .toList();

      final pagination = response['pagination'] as Map<String, dynamic>;
      final page   = pagination['page'] as int;
      final pages  = pagination['pages'] as int;
      final total  = pagination['total'] as int;

      state = state.copyWith(
        items:      refresh ? newItems : [...state.items, ...newItems],
        isLoading:  false,
        hasMore:    page < pages,
        totalCount: total,
      );
      _currentFilter = _currentFilter.copyWith(page: page + 1);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> applyFilter(MediaFilter filter) async {
    _currentFilter = filter.copyWith(page: 1);
    state = const MediaListState();
    await loadMedia(refresh: true);
  }

  Future<void> refresh() => loadMedia(refresh: true);
}

final mediaProvider = StateNotifierProvider<MediaNotifier, MediaListState>(
  (ref) => MediaNotifier(ref.read(apiServiceProvider)),
);

// ─── Admin Queue Provider ─────────────────────────────────────────────────
final adminQueueProvider = FutureProvider<List<MediaModel>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getAdminQueue();
});

// ─── Dashboard Stats Provider ─────────────────────────────────────────────
final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getDashboardStats();
});

// ─── Upload Queue Provider ────────────────────────────────────────────────
final uploadQueueProvider = FutureProvider<List<UploadModel>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getUploadQueue();
});

// ─── Pending Uploads (local) ──────────────────────────────────────────────
class PendingUploadsNotifier extends StateNotifier<List<PendingUpload>> {
  PendingUploadsNotifier() : super([]);

  void add(PendingUpload upload) {
    state = [...state, upload];
  }

  void updateProgress(String localId, double progress, {String? status}) {
    state = state.map((u) {
      if (u.localId == localId) {
        u.progress = progress;
        if (status != null) u.status = status;
      }
      return u;
    }).toList();
  }

  void remove(String localId) {
    state = state.where((u) => u.localId != localId).toList();
  }

  void setError(String localId, String error) {
    state = state.map((u) {
      if (u.localId == localId) {
        u.status = 'failed';
        u.error = error;
      }
      return u;
    }).toList();
  }
}

final pendingUploadsProvider =
    StateNotifierProvider<PendingUploadsNotifier, List<PendingUpload>>(
  (ref) => PendingUploadsNotifier(),
);
