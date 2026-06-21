import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logger/logger.dart';
import 'api_client.dart';
import '../models/subscription_model.dart';

/// Wires Google Play Billing (via `in_app_purchase`) to the ADM AI backend.
///
/// Flow: user taps "Subscribe" → Play Store billing sheet opens → on
/// successful purchase, the raw purchase token is sent to
/// `POST /api/subscriptions/purchase`, where the backend verifies it
/// against the Google Play Developer API (see backend/src/services/googlePlay.js).
/// When `GOOGLE_PLAY_SERVICE_ACCOUNT_KEY` env var points to a valid service-account
/// JSON key, purchases are fully verified server-side; without it, the backend
/// trusts the client receipt as a fallback.
///
/// On platforms/builds where Play Billing isn't available (e.g. this repo
/// has no `google-services.json` / signed release build), [isAvailable]
/// returns false and the UI should fall back to the existing demo flow.
class PurchaseService {
  static const Map<SubscriptionPlan, String> productIds = {
    SubscriptionPlan.pro: 'adm_ai_pro_monthly',
    SubscriptionPlan.ultra: 'adm_ai_ultra_monthly',
    SubscriptionPlan.vip: 'adm_ai_vip_monthly',
  };

  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  final ApiClient _api = ApiClient();
  final Logger _logger = Logger();

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  void Function(SubscriptionPlan plan)? _onActivated;
  void Function(String message)? _onError;

  Future<bool> get isAvailable async {
    if (!Platform.isAndroid) return false;
    return _iap.isAvailable();
  }

  /// Starts listening to the purchase update stream. Call once at app
  /// startup (or when entering the subscription screen).
  void initialize({
    required void Function(SubscriptionPlan plan) onActivated,
    required void Function(String message) onError,
  }) {
    _onActivated = onActivated;
    _onError = onError;
    _subscription ??= _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (e) => _onError?.call('Xarid oqimida xato: $e'),
    );
  }

  Future<List<ProductDetails>> loadProducts() async {
    final response = await _iap.queryProductDetails(productIds.values.toSet());
    if (response.error != null) {
      _logger.w('Mahsulotlarni yuklashda xato: ${response.error}');
    }
    return response.productDetails;
  }

  /// Launches the Google Play billing sheet for [plan].
  Future<bool> buy(SubscriptionPlan plan, ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.error:
          _onError?.call(purchase.error?.message ?? 'Xarid amalga oshmadi');
          break;
        case PurchaseStatus.canceled:
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndActivate(purchase);
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _verifyAndActivate(PurchaseDetails purchase) async {
    final plan = productIds.entries
        .firstWhere(
          (e) => e.value == purchase.productID,
          orElse: () => const MapEntry(SubscriptionPlan.free, ''),
        )
        .key;

    if (plan == SubscriptionPlan.free) return;

    try {
      await _api.post('/subscriptions/purchase', data: {
        'plan': plan.name,
        'provider': 'google_play',
        'purchaseToken': purchase.verificationData.serverVerificationData,
        'productId': purchase.productID,
      });
      _onActivated?.call(plan);
    } on ApiException catch (e) {
      _onError?.call(e.message);
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
