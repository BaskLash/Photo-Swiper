import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

/// Wraps RevenueCat. Single source of truth for paywall state.
///
/// Listen to this notifier from the UI to react to entitlement changes —
/// the SDK pushes updates via [Purchases.addCustomerInfoUpdateListener] and
/// they are forwarded here so any widget watching `isPro` rebuilds the
/// instant a purchase, refund, or restore lands.
class PurchaseService extends ChangeNotifier {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  // Replace with the API keys from your RevenueCat dashboard
  // (Project Settings → API keys → Public app-specific keys).
  // The keys are not secrets — they ship in the binary.
  static const String _iosApiKey = 'appl_QCUIPaEXiDiDwVkLdoLVOIbinUM';
  static const String _androidApiKey = 'goog_REPLACE_WITH_ANDROID_KEY';

  // Must match the entitlement identifier configured in RevenueCat.
  static const String entitlementId = 'pro';

  bool _initialized = false;
  bool _isPro = false;
  Offerings? _offerings;
  String? _lastError;

  bool get isPro => _isPro;
  bool get isInitialized => _initialized;
  Offering? get currentOffering => _offerings?.current;
  String? get lastError => _lastError;
  bool get hasOfferingButNoPackages =>
      _offerings?.current != null &&
      _offerings!.current!.availablePackages.isEmpty;
  bool get hasNoCurrentOffering =>
      _offerings != null && _offerings!.current == null;

  /// Initializes the SDK. Safe to call multiple times — subsequent calls are
  /// no-ops. Failures are swallowed so a misconfigured key never crashes the
  /// app; the user simply stays on the free tier until config is fixed.
  Future<void> init() async {
    if (_initialized) return;
    if (!_supportedPlatform) {
      _initialized = true;
      return;
    }
    final apiKey = Platform.isIOS ? _iosApiKey : _androidApiKey;
    if (apiKey.contains('REPLACE_WITH')) {
      _lastError = 'API key not configured for this platform.';
      debugPrint('[PurchaseService] $_lastError');
      _initialized = true;
      return;
    }

    try {
      // Verbose logging on debug builds — surfaces the real reason a purchase
      // or fetch fails (key invalid, products not synced, etc.) in console.
      await Purchases.setLogLevel(
          kDebugMode ? LogLevel.debug : LogLevel.warn);
      await Purchases.configure(PurchasesConfiguration(apiKey));

      final info = await Purchases.getCustomerInfo();
      _isPro = _hasProEntitlement(info);

      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdate);

      // Pre-fetch offerings so the paywall opens instantly.
      _offerings = await Purchases.getOfferings();
      _lastError = null;
    } on PlatformException catch (e) {
      _lastError = _describeError(e);
      debugPrint('[PurchaseService] init failed: $_lastError');
    } catch (e) {
      _lastError = e.toString();
      debugPrint('[PurchaseService] init failed: $_lastError');
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  String _describeError(PlatformException e) {
    final code = PurchasesErrorHelper.getErrorCode(e);
    final detail = e.message ?? code.toString();
    return '${code.name}: $detail';
  }

  /// Forces a fresh fetch of offerings from RevenueCat. Call from the paywall
  /// when offerings weren't pre-fetched (e.g. init ran offline).
  Future<Offering?> fetchOfferings() async {
    if (!_supportedPlatform) return null;
    try {
      _offerings = await Purchases.getOfferings();
      _lastError = null;
      notifyListeners();
      return _offerings?.current;
    } on PlatformException catch (e) {
      _lastError = _describeError(e);
      debugPrint('[PurchaseService] fetchOfferings failed: $_lastError');
      notifyListeners();
      return null;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('[PurchaseService] fetchOfferings failed: $_lastError');
      notifyListeners();
      return null;
    }
  }

  /// Attempts to purchase [package]. Returns true if the user is now pro.
  /// User-cancelled purchases return false without throwing.
  Future<bool> purchase(Package package) async {
    if (!_supportedPlatform) return false;
    try {
      final result = await Purchases.purchasePackage(package);
      _isPro = _hasProEntitlement(result);
      notifyListeners();
      return _isPro;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) return false;
      debugPrint('[PurchaseService] purchase failed: $code');
      rethrow;
    }
  }

  /// Restores previously-purchased entitlements. Returns true if a pro
  /// entitlement was found and applied.
  Future<bool> restore() async {
    if (!_supportedPlatform) return _isPro;
    try {
      final info = await Purchases.restorePurchases();
      _isPro = _hasProEntitlement(info);
      notifyListeners();
      return _isPro;
    } catch (e) {
      debugPrint('[PurchaseService] restore failed: $e');
      return _isPro;
    }
  }

  void _onCustomerInfoUpdate(CustomerInfo info) {
    final next = _hasProEntitlement(info);
    if (next != _isPro) {
      _isPro = next;
      notifyListeners();
    }
  }

  bool _hasProEntitlement(CustomerInfo info) {
    final ent = info.entitlements.active[entitlementId];
    return ent != null && ent.isActive;
  }

  bool get _supportedPlatform => Platform.isIOS || Platform.isAndroid;
}
