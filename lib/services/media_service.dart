import 'package:photo_manager/photo_manager.dart';

/// Central service for all photo_manager interactions.
/// Uses FilterOptionGroup.createTimeCond for O(month) queries
/// so performance stays constant even with 40,000+ total items.
class MediaService {
  MediaService._();
  static final MediaService instance = MediaService._();

  // ─── Permission ────────────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    final ps = await PhotoManager.requestPermissionExtend();
    return ps.isAuth || ps.hasAccess;
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Future<AssetPathEntity?> _album({FilterOptionGroup? filter}) async {
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      hasAll: true,
      onlyAll: true,
      filterOption: filter ?? FilterOptionGroup(),
    );
    return paths.isEmpty ? null : paths.first;
  }

  FilterOptionGroup _monthFilter(int month, int year) {
    final start = DateTime(year, month, 1);
    final end = (month == 12)
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);

    return FilterOptionGroup(
      createTimeCond: DateTimeCond(
        min: start,
        max: end.subtract(const Duration(milliseconds: 1)),
      ),
      orders: [
        OrderOption(type: OrderOptionType.createDate, asc: false),
      ],
    );
  }

  // ─── Year range ──────────────────────────────────────────────────────────────

  Future<List<int>> getAvailableYears() async {
    try {
      final album = await _album();
      if (album == null) return [DateTime.now().year];

      final count = await album.assetCountAsync;
      if (count == 0) return [DateTime.now().year];

      final newest = await album.getAssetListRange(start: 0, end: 1);
      final oldest =
          await album.getAssetListRange(start: count - 1, end: count);

      if (newest.isEmpty) return [DateTime.now().year];

      final newestYear = newest.first.createDateTime.year;
      final oldestYear =
          oldest.isEmpty ? newestYear : oldest.first.createDateTime.year;

      final span = (newestYear - oldestYear + 1).clamp(1, 30);
      return List.generate(span, (i) => newestYear - i);
    } catch (_) {
      return [DateTime.now().year];
    }
  }

  // ─── Month counts ────────────────────────────────────────────────────────────

  Future<int> getMonthCount(int month, int year) async {
    try {
      final album = await _album(filter: _monthFilter(month, year));
      if (album == null) return 0;
      return await album.assetCountAsync;
    } catch (_) {
      return 0;
    }
  }

  // ─── Load media ──────────────────────────────────────────────────────────────

  Future<List<AssetEntity>> loadMonthMedia(int month, int year) async {
    try {
      final album = await _album(filter: _monthFilter(month, year));
      if (album == null) return [];

      final count = await album.assetCountAsync;
      if (count == 0) return [];

      const batchSize = 200;
      final all = <AssetEntity>[];

      for (int page = 0; ; page++) {
        final batch =
            await album.getAssetListPaged(page: page, size: batchSize);
        if (batch.isEmpty) break;
        all.addAll(batch);
      }

      return all;
    } catch (_) {
      return [];
    }
  }

  Future<List<AssetEntity>> loadTodayMedia() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end =
        DateTime(now.year, now.month, now.day + 1)
            .subtract(const Duration(milliseconds: 1));

    try {
      final filter = FilterOptionGroup(
        createTimeCond: DateTimeCond(min: start, max: end),
        orders: [OrderOption(type: OrderOptionType.createDate, asc: false)],
      );
      final album = await _album(filter: filter);
      if (album == null) return [];
      final count = await album.assetCountAsync;
      if (count == 0) return [];
      return await album.getAssetListRange(start: 0, end: count);
    } catch (_) {
      return [];
    }
  }

  Future<List<AssetEntity>> loadRandomMedia({int limit = 50}) async {
    try {
      final album = await _album();
      if (album == null) return [];
      final count = await album.assetCountAsync;
      if (count == 0) return [];

      // Sample from the whole library, shuffled
      final sample = (count < limit) ? count : limit;
      final assets = await album.getAssetListRange(start: 0, end: sample * 5 > count ? count : sample * 5);
      assets.shuffle();
      return assets.take(limit).toList();
    } catch (_) {
      return [];
    }
  }

  // ─── File size ────────────────────────────────────────────────────────────────

  Future<int?> getFileSize(AssetEntity asset) async {
    try {
      final file = await asset.originFile;
      if (file == null) return null;
      return await file.length();
    } catch (_) {
      return null;
    }
  }

  // ─── Delete ──────────────────────────────────────────────────────────────────

  Future<List<String>> deleteAssets(List<AssetEntity> assets) async {
    if (assets.isEmpty) return [];
    try {
      final ids = assets.map((a) => a.id).toList();
      return await PhotoManager.editor.deleteWithIds(ids);
    } catch (_) {
      return [];
    }
  }
}
