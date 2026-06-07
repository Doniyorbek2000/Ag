import 'package:url_launcher/url_launcher.dart';

import 'api_client.dart';

enum LocalPaymentProvider { click, payme }

extension LocalPaymentProviderX on LocalPaymentProvider {
  String get id => this == LocalPaymentProvider.click ? 'click' : 'payme';
  String get label => this == LocalPaymentProvider.click ? 'Click' : 'Payme';
}

/// Bridges to the backend's `/api/payments/{click,payme}/*` routes
/// (`backend/src/routes/payments.js`) -- creates a hosted-checkout order and
/// opens it in the browser/payment app via [url_launcher]. The actual
/// payment confirmation happens server-side through each provider's webhook;
/// the app finds out the plan was activated the next time it refreshes the
/// user profile (e.g. pull-to-refresh, or re-opening the subscription screen).
///
/// Requires the backend to have CLICK_*/PAYME_* merchant credentials
/// configured (see backend/README.md "Click va Payme orqali to'lov qabul
/// qilish") -- without them the create-order call fails with a clear
/// "not configured" error rather than opening a broken checkout page.
class LocalPaymentService {
  final ApiClient _api = ApiClient();

  Future<String> createCheckout({
    required LocalPaymentProvider provider,
    required String plan,
    String? returnUrl,
  }) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/payments/${provider.id}/create',
        data: {
          'plan': plan,
          if (returnUrl != null) 'returnUrl': returnUrl,
        },
      );
      final checkoutUrl = response.data?['checkoutUrl'] as String?;
      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        throw ApiException('To\'lov havolasini olib bo\'lmadi');
      }
      return checkoutUrl;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('To\'lov tizimiga ulanishda xato yuz berdi');
    }
  }

  Future<bool> openCheckout(String checkoutUrl) {
    final uri = Uri.tryParse(checkoutUrl);
    if (uri == null) return Future.value(false);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
