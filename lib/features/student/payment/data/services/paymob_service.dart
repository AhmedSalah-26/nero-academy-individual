import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Paymob payment service
class PaymobService {
  PaymobService._();
  static final PaymobService instance = PaymobService._();

  static bool _isInitialized = false;
  static String _apiKey = '';
  static int _integrationId = 0;
  static int _walletIntegrationId = 0;
  static int _iFrameId = 0;

  /// Initialize Paymob SDK
  static Future<void> initialize({
    required String apiKey,
    required int integrationId,
    required int iFrameId,
    int walletIntegrationId = 0,
  }) async {
    _apiKey = apiKey;
    _integrationId = integrationId;
    _walletIntegrationId = walletIntegrationId;
    _iFrameId = iFrameId;
    _isInitialized = true;
  }

  /// Check if Paymob is initialized
  static bool get isInitialized => _isInitialized;

  /// Get payment URL for card payment
  Future<String?> getPaymentUrl({
    required double amount,
    required String orderId,
    String currency = 'EGP',
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) async {
    if (!_isInitialized) {
      debugPrint('❌ [Paymob] Service not initialized');
      return null;
    }

    try {
      debugPrint(
          '🔵 [Paymob] Starting payment flow for amount: $amount EGP, orderId: $orderId');

      // Step 1: Get auth token
      debugPrint('🔵 [Paymob] Step 1: Getting auth token...');
      final authToken = await _getAuthToken();
      if (authToken == null) {
        debugPrint('❌ [Paymob] Failed to get auth token');
        return null;
      }
      debugPrint('✅ [Paymob] Auth token obtained');

      // Step 2: Create order with our order ID as merchant_order_id
      final amountCents = (amount * 100).toInt();
      debugPrint(
          '🔵 [Paymob] Step 2: Creating order with amount: $amountCents cents');
      final paymobOrderId = await _createOrder(
        authToken,
        amountCents,
        currency,
        merchantOrderId: orderId,
      );
      if (paymobOrderId == null) {
        debugPrint('❌ [Paymob] Failed to create order');
        return null;
      }
      debugPrint('✅ [Paymob] Order created with ID: $paymobOrderId');

      // Step 3: Get payment key
      debugPrint('🔵 [Paymob] Step 3: Getting payment key...');
      final paymentKey = await _getPaymentKey(
        authToken: authToken,
        orderId: paymobOrderId,
        amountCents: amountCents,
        currency: currency,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
      );
      if (paymentKey == null) {
        debugPrint('❌ [Paymob] Failed to get payment key');
        return null;
      }
      debugPrint('✅ [Paymob] Payment key obtained');

      // Return iFrame URL
      final iframeUrl =
          'https://accept.paymob.com/api/acceptance/iframes/$_iFrameId?payment_token=$paymentKey';
      debugPrint('✅ [Paymob] Payment URL generated successfully');
      return iframeUrl;
    } catch (e) {
      debugPrint('❌ [Paymob] Exception: $e');
      return null;
    }
  }

  Future<String?> _getAuthToken() async {
    try {
      debugPrint('🔵 [Paymob] Requesting auth token...');
      final response = await http.post(
        Uri.parse('https://accept.paymob.com/api/auth/tokens'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'api_key': _apiKey}),
      );

      debugPrint('🔵 [Paymob] Auth response status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['token'];
      } else {
        debugPrint('❌ [Paymob] Auth failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ [Paymob] Auth exception: $e');
    }
    return null;
  }

  Future<int?> _createOrder(
    String authToken,
    int amountCents,
    String currency, {
    String? merchantOrderId,
  }) async {
    try {
      debugPrint('🔵 [Paymob] Creating order with amount: $amountCents cents');
      final response = await http.post(
        Uri.parse('https://accept.paymob.com/api/ecommerce/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'auth_token': authToken,
          'delivery_needed': false,
          'amount_cents': amountCents.toString(),
          'currency': currency,
          'merchant_order_id': merchantOrderId,
          'items': [],
        }),
      );

      debugPrint(
          '🔵 [Paymob] Create order response status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id'];
      } else {
        debugPrint('❌ [Paymob] Create order failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ [Paymob] Create order exception: $e');
    }
    return null;
  }

  Future<String?> _getPaymentKey({
    required String authToken,
    required int orderId,
    required int amountCents,
    required String currency,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) async {
    try {
      final nameParts = (customerName ?? 'Customer').split(' ');
      final firstName = nameParts.first;
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'Name';

      debugPrint(
          '🔵 [Paymob] Getting payment key for order: $orderId, integration: $_integrationId');

      // Ensure phone number is not empty and has valid format
      String phoneNumber = customerPhone ?? '+201000000000';
      if (phoneNumber.isEmpty) {
        phoneNumber = '+201000000000';
      }
      // Remove any spaces or special characters except +
      phoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      // Ensure it starts with +20 for Egypt
      if (!phoneNumber.startsWith('+')) {
        if (phoneNumber.startsWith('20')) {
          phoneNumber = '+$phoneNumber';
        } else if (phoneNumber.startsWith('0')) {
          phoneNumber = '+2$phoneNumber';
        } else {
          phoneNumber = '+20$phoneNumber';
        }
      }

      debugPrint('🔵 [Paymob] Using phone number: $phoneNumber');

      final response = await http.post(
        Uri.parse('https://accept.paymob.com/api/acceptance/payment_keys'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'auth_token': authToken,
          'amount_cents': amountCents.toString(),
          'expiration': 3600,
          'order_id': orderId.toString(),
          'billing_data': {
            'apartment': 'NA',
            'email': customerEmail ?? 'customer@example.com',
            'floor': 'NA',
            'first_name': firstName,
            'street': 'NA',
            'building': 'NA',
            'phone_number': phoneNumber,
            'shipping_method': 'NA',
            'postal_code': 'NA',
            'city': 'NA',
            'country': 'EG',
            'last_name': lastName,
            'state': 'NA',
          },
          'currency': currency,
          'integration_id': _integrationId,
        }),
      );

      debugPrint(
          '🔵 [Paymob] Payment key response status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['token'];
      } else {
        debugPrint('❌ [Paymob] Payment key failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ [Paymob] Payment key exception: $e');
    }
    return null;
  }

  /// Get wallet payment URL
  Future<String?> getWalletPaymentUrl({
    required double amount,
    required String orderId,
    required String walletPhoneNumber,
    String currency = 'EGP',
    String? customerName,
    String? customerEmail,
  }) async {
    if (!_isInitialized || _walletIntegrationId == 0) {
      debugPrint('❌ Wallet payment not initialized or integration ID is 0');
      return null;
    }

    // Format phone number - remove any non-digit characters and ensure it starts with 01
    String formattedPhone = walletPhoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (formattedPhone.startsWith('+20')) {
      formattedPhone = formattedPhone.substring(3);
    } else if (formattedPhone.startsWith('20')) {
      formattedPhone = formattedPhone.substring(2);
    }
    // Ensure it starts with 01 (Egyptian mobile format)
    if (!formattedPhone.startsWith('01')) {
      formattedPhone = '01$formattedPhone';
    }

    debugPrint('🔵 Wallet Phone Number (formatted): $formattedPhone');

    try {
      // Step 1: Get auth token
      final authToken = await _getAuthToken();
      if (authToken == null) {
        debugPrint('❌ Failed to get auth token');
        return null;
      }

      // Step 2: Create order
      final amountCents = (amount * 100).toInt();
      final paymobOrderId = await _createOrder(
        authToken,
        amountCents,
        currency,
        merchantOrderId: orderId,
      );
      if (paymobOrderId == null) {
        debugPrint('❌ Failed to create Paymob order');
        return null;
      }

      debugPrint('🔵 Paymob Order ID: $paymobOrderId');

      // Step 3: Get payment key for wallet
      final paymentKey = await _getWalletPaymentKey(
        authToken: authToken,
        orderId: paymobOrderId,
        amountCents: amountCents,
        currency: currency,
        walletPhoneNumber: formattedPhone,
        customerName: customerName,
        customerEmail: customerEmail,
      );
      if (paymentKey == null) {
        debugPrint('❌ Failed to get wallet payment key');
        return null;
      }

      debugPrint('🔵 Got wallet payment key');

      // Step 4: Request wallet payment
      final redirectUrl =
          await _requestWalletPayment(paymentKey, formattedPhone);
      return redirectUrl;
    } catch (e) {
      debugPrint('❌ Wallet payment exception: $e');
      return null;
    }
  }

  Future<String?> _getWalletPaymentKey({
    required String authToken,
    required int orderId,
    required int amountCents,
    required String currency,
    required String walletPhoneNumber,
    String? customerName,
    String? customerEmail,
  }) async {
    try {
      final nameParts = (customerName ?? 'Customer').split(' ');
      final firstName = nameParts.first;
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'Name';

      final response = await http.post(
        Uri.parse('https://accept.paymob.com/api/acceptance/payment_keys'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'auth_token': authToken,
          'amount_cents': amountCents.toString(),
          'expiration': 3600,
          'order_id': orderId.toString(),
          'billing_data': {
            'apartment': 'NA',
            'email': customerEmail ?? 'customer@example.com',
            'floor': 'NA',
            'first_name': firstName,
            'street': 'NA',
            'building': 'NA',
            'phone_number': walletPhoneNumber,
            'shipping_method': 'NA',
            'postal_code': 'NA',
            'city': 'NA',
            'country': 'EG',
            'last_name': lastName,
            'state': 'NA',
          },
          'currency': currency,
          'integration_id': _walletIntegrationId,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['token'];
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _requestWalletPayment(
      String paymentKey, String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse('https://accept.paymob.com/api/acceptance/payments/pay'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'source': {
            'identifier': phoneNumber,
            'subtype': 'WALLET',
          },
          'payment_token': paymentKey,
        }),
      );

      debugPrint('🔵 Wallet Payment Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check for error message first
        final errorMessage = data['data.message'] as String?;
        final success = data['success'] as bool? ?? false;

        if (!success && errorMessage != null) {
          debugPrint('❌ Wallet Payment Failed: $errorMessage');
          // Return error message prefixed with ERROR: so caller can handle it
          return 'ERROR:$errorMessage';
        }

        // Get redirect URL
        final redirectUrl = data['redirect_url'] as String?;
        final iframeUrl = data['iframe_redirection_url'] as String?;
        final redirectionUrl = data['redirection_url'] as String?;

        debugPrint('🔵 redirect_url: $redirectUrl');
        debugPrint('🔵 iframe_redirection_url: $iframeUrl');

        // Return the first valid URL
        final url = redirectUrl ?? iframeUrl ?? redirectionUrl;

        if (url != null && url.isNotEmpty && !url.contains('success=false')) {
          return url;
        }

        debugPrint('❌ No valid redirect URL found');
        return null;
      } else {
        debugPrint('❌ Wallet Payment Error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Wallet Payment Exception: $e');
      return null;
    }
  }

  /// Check if wallet payment is available
  static bool get isWalletPaymentAvailable =>
      _isInitialized && _walletIntegrationId > 0;
}
