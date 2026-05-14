import 'package:posthog_flutter/posthog_flutter.dart';

/// Thin wrapper around PostHog. All calls are swallowed on failure so a
/// broken analytics layer can never crash the app or interrupt the user.
///
/// PostHog is configured via Info.plist (iOS) and AndroidManifest.xml
/// (Android); this service does not pass an API key. The native SDK
/// auto-initializes on first use from those manifest keys.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  Future<void> init() async {
    try {
      await Posthog().enable();
    } catch (_) {
      // Silent fail — analytics must never crash the app.
    }
  }

  Future<void> track(
    String event, {
    Map<String, Object>? properties,
  }) async {
    try {
      await Posthog().capture(
        eventName: event,
        properties: properties,
      );
    } catch (_) {
      // Silent fail.
    }
  }

  Future<void> screen(
    String screenName, {
    Map<String, Object>? properties,
  }) async {
    try {
      await Posthog().screen(
        screenName: screenName,
        properties: properties,
      );
    } catch (_) {
      // Silent fail.
    }
  }

  /// Registers super properties — values attached to every subsequent event
  /// for the anonymous distinct ID. PostHog's `register` API takes one
  /// key/value pair at a time, so we iterate here.
  Future<void> setUserProperties(Map<String, Object> properties) async {
    try {
      for (final entry in properties.entries) {
        await Posthog().register(entry.key, entry.value);
      }
    } catch (_) {
      // Silent fail.
    }
  }
}
