/// Canonical event names and property keys. Use these constants — never
/// inline strings — so renames don't silently fragment the dashboard.
class AnalyticsEvents {
  AnalyticsEvents._();

  // App lifecycle
  static const String appOpened = 'app_opened';
  static const String appBackgrounded = 'app_backgrounded';

  // Permissions
  static const String photoPermissionRequested = 'photo_permission_requested';
  static const String photoPermissionGranted = 'photo_permission_granted';
  static const String photoPermissionDenied = 'photo_permission_denied';

  // Gallery loading
  static const String galleryLoadStarted = 'gallery_load_started';
  static const String galleryLoadCompleted = 'gallery_load_completed';
  static const String galleryLoadFailed = 'gallery_load_failed';

  // Core cleanup loop
  static const String cleanupStarted = 'cleanup_started';
  static const String swipePerformed = 'swipe_performed';
  static const String cleanupPaused = 'cleanup_paused';
  static const String cleanupReviewOpened = 'cleanup_review_opened';
  static const String cleanupConfirmed = 'cleanup_confirmed';
  static const String cleanupCanceled = 'cleanup_canceled';

  // Monetization
  static const String paywallShown = 'paywall_shown';
  static const String paywallDismissed = 'paywall_dismissed';
  static const String subscriptionStarted = 'subscription_started';
  static const String subscriptionRestored = 'subscription_restored';

  // Navigation
  static const String screenViewed = 'screen_viewed';

  // Errors
  static const String errorOccurred = 'error_occurred';
}
