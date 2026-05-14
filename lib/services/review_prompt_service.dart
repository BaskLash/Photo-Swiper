import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Triggers the App Store / Play Store in-app review prompt after a
/// confirmed cleanup that meets engagement and storage-freed thresholds.
///
/// Apple caps real prompts at 3 per user per 365 days regardless of how
/// often we call the API, so this gates requests on cumulative engagement
/// to spend each shot on a likely-satisfied user.
class ReviewPromptService {
  ReviewPromptService._();
  static final ReviewPromptService instance = ReviewPromptService._();

  static const String _keyLaunchCount = 'flickclean.review.launchCount';
  static const String _keyCleanupSessionCount =
      'flickclean.review.cleanupSessionCount';
  static const String _keyLastPromptTimestamp =
      'flickclean.review.lastPromptTimestamp';
  static const String _keyLastPromptedVersion =
      'flickclean.review.lastPromptedVersion';

  static const int _minimumBytesFreed = 500 * 1024 * 1024; // 500 MB
  static const int _minimumLaunches = 3;
  static const int _minimumCleanupSessions = 2;
  static const Duration _minimumTimeBetweenPrompts = Duration(days: 7);

  final InAppReview _inAppReview = InAppReview.instance;

  Future<void> recordAppLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyLaunchCount) ?? 0;
    await prefs.setInt(_keyLaunchCount, current + 1);
  }

  Future<void> recordCleanupCompleted({required int freedBytes}) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyCleanupSessionCount) ?? 0;
    await prefs.setInt(_keyCleanupSessionCount, current + 1);

    if (await _shouldRequestReview(freedBytes)) {
      await _requestReview();
    }
  }

  Future<bool> _shouldRequestReview(int freedBytes) async {
    if (freedBytes < _minimumBytesFreed) return false;

    final prefs = await SharedPreferences.getInstance();

    final launches = prefs.getInt(_keyLaunchCount) ?? 0;
    if (launches < _minimumLaunches) return false;

    final sessions = prefs.getInt(_keyCleanupSessionCount) ?? 0;
    if (sessions < _minimumCleanupSessions) return false;

    final lastPromptMs = prefs.getInt(_keyLastPromptTimestamp) ?? 0;
    if (lastPromptMs > 0) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastPromptMs);
      if (DateTime.now().difference(last) < _minimumTimeBetweenPrompts) {
        return false;
      }
    }

    final info = await PackageInfo.fromPlatform();
    final lastVersion = prefs.getString(_keyLastPromptedVersion);
    if (lastVersion == info.version) return false;

    return true;
  }

  Future<void> _requestReview() async {
    try {
      if (!await _inAppReview.isAvailable()) return;
      await _inAppReview.requestReview();

      final prefs = await SharedPreferences.getInstance();
      final info = await PackageInfo.fromPlatform();
      await prefs.setInt(
        _keyLastPromptTimestamp,
        DateTime.now().millisecondsSinceEpoch,
      );
      await prefs.setString(_keyLastPromptedVersion, info.version);
    } catch (_) {
      // Swallow platform errors — review prompt failure must never crash
      // the app or interrupt the user's cleanup flow.
    }
  }
}
