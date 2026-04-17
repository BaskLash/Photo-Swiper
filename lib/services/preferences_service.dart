import 'package:shared_preferences/shared_preferences.dart';

/// Persists user preferences across app launches.
/// Call [init] once in main() before runApp.
class PreferencesService {
  PreferencesService._();
  static final PreferencesService instance = PreferencesService._();

  static const _keyLeftHanded = 'left_handed_mode';

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
}
