import 'package:shared_preferences/shared_preferences.dart';

/// Persists user preferences across app launches.
/// Call [init] once in main() before runApp.
class PreferencesService {
  PreferencesService._();
  static final PreferencesService instance = PreferencesService._();

  static const _keyLeftHanded = 'left_handed_mode';
  static const _keyOnboarding = 'has_seen_onboarding';
  static const _keySwipeHintCount = 'swipe_hint_count';
  static const _keyLifetimeSwipes = 'lifetime_swipe_count';

  // Free tier allowance — once reached, the paywall blocks further swipes
  // until the user purchases a `pro` entitlement. Kept here as the single
  // source of truth so screens and services agree on the threshold.
  static const int kFreeSwipeLimit = 10;

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ─── Left-handed mode ─────────────────────────────────────────────────────
  // false (default): swipe right = keep,   swipe left = delete
  // true:            swipe right = delete,  swipe left = keep

  bool get isLeftHanded => _prefs.getBool(_keyLeftHanded) ?? false;

  Future<void> setLeftHanded(bool value) =>
      _prefs.setBool(_keyLeftHanded, value);

  // ─── Onboarding ───────────────────────────────────────────────────────────
  bool get hasSeenOnboarding => _prefs.getBool(_keyOnboarding) ?? false;

  Future<void> setHasSeenOnboarding(bool value) =>
      _prefs.setBool(_keyOnboarding, value);

  // ─── Swipe hint fade-out ──────────────────────────────────────────────────
  // Counts completed swipes; used to progressively fade the edge direction
  // hints. Capped at 20 — once hints are invisible there's no point tracking.
  int get swipeHintCount => _prefs.getInt(_keySwipeHintCount) ?? 0;

  Future<void> incrementSwipeHintCount() async {
    final n = swipeHintCount;
    if (n < 20) await _prefs.setInt(_keySwipeHintCount, n + 1);
  }

  // ─── Lifetime swipe counter ───────────────────────────────────────────────
  // Used by the paywall trigger. Counts every committed swipe decision across
  // the lifetime of the install; not capped, so we can also surface usage
  // stats later. Reset only via `resetLifetimeSwipes` (debug / pro purchase).
  int get lifetimeSwipes => _prefs.getInt(_keyLifetimeSwipes) ?? 0;

  Future<void> incrementLifetimeSwipes() =>
      _prefs.setInt(_keyLifetimeSwipes, lifetimeSwipes + 1);

  Future<void> resetLifetimeSwipes() => _prefs.setInt(_keyLifetimeSwipes, 0);
}
