import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lms_platform/core/shared_widgets/error_state.dart';
import 'package:lms_platform/features/student/payment/domain/entities/payment_result.dart';

class PaymentWebView extends StatefulWidget {
  final String paymentUrl;
  final Function(PaymentResult) onPaymentComplete;
  final VoidCallback onCancel;
  final bool isWalletPayment;

  const PaymentWebView({
    super.key,
    required this.paymentUrl,
    required this.onPaymentComplete,
    required this.onCancel,
    this.isWalletPayment = false,
  });

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController? _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // On web, open payment in new tab
      _openPaymentInBrowser();
    } else {
      _initWebView();
    }
  }

  Future<void> _openPaymentInBrowser() async {
    try {
      final uri = Uri.parse(widget.paymentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        // Show message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.locale.languageCode == 'ar'
                    ? 'تم فتح صفحة الدفع في المتصفح'
                    : 'Payment page opened in browser',
              ),
            ),
          );
          // Close this screen
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('Error opening payment URL: $e');
      if (mounted) {
        widget.onPaymentComplete(PaymentResult.failure(
          message: 'Failed to open payment page',
        ));
        Navigator.pop(context);
      }
    }
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(true)
      ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('🔵 WebView Page Started: $url');
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onPageFinished: (url) {
            debugPrint('🔵 WebView Page Finished: $url');
            // Inject viewport meta tag for better mobile scaling
            _controller?.runJavaScript('''
              var meta = document.querySelector('meta[name="viewport"]');
              if (!meta) {
                meta = document.createElement('meta');
                meta.name = 'viewport';
                document.head.appendChild(meta);
              }
              meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=3.0, user-scalable=yes';
              
              // Try to make content more mobile-friendly
              document.body.style.minWidth = 'auto';
              document.body.style.overflowX = 'hidden';
            ''');
            setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            debugPrint('❌ WebView Error: ${error.description}');
            setState(() {
              _isLoading = false;
              _errorMessage = error.description;
            });
          },
          onNavigationRequest: (request) {
            final url = request.url;
            debugPrint('🔵 WebView Navigation: $url');

            // Check for success indicators (multiple formats)
            if (url.contains('success=true') ||
                url.contains('payment=success') ||
                url.contains('txn_response_code=APPROVED') ||
                url.contains('pending=false') && url.contains('success=true')) {
              debugPrint('✅ Payment Success detected');
              _handleSuccess(url);
              return NavigationDecision.prevent;
            }

            // Check for failure indicators
            if (url.contains('success=false') ||
                url.contains('payment=failed') ||
                url.contains('payment=failure') ||
                url.contains('txn_response_code=DECLINED') ||
                url.contains('pending=false') &&
                    url.contains('success=false')) {
              debugPrint('❌ Payment Failure detected');
              _handleFailure(url);
              return NavigationDecision.prevent;
            }

            // For wallet payments, allow navigation to wallet provider pages
            // These are external URLs that handle the actual payment
            if (widget.isWalletPayment) {
              // Allow all navigations for wallet - the wallet provider will redirect back
              return NavigationDecision.navigate;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));

    debugPrint('🔵 Loading payment URL: ${widget.paymentUrl}');
  }

  void _handleSuccess(String url) {
    try {
      debugPrint('🔵 Handling success URL: $url');
      final uri = Uri.parse(url);

      // Extract transaction ID from various possible parameters
      final transactionId = uri.queryParameters['id'] ??
          uri.queryParameters['transaction_id'] ??
          uri.queryParameters['txn_id'] ??
          uri.queryParameters['order_id'] ??
          uri.queryParameters['merchant_order_id'] ??
          '';

      debugPrint('✅ Transaction ID: $transactionId');

      widget.onPaymentComplete(PaymentResult.success(
        transactionId: transactionId.isNotEmpty ? transactionId : 'success',
        message: 'Payment successful',
      ));
    } catch (e) {
      debugPrint('❌ Error handling success: $e');
      widget.onPaymentComplete(PaymentResult.failure(
        message: 'Error processing payment result',
      ));
    }
  }

  void _handleFailure(String url) {
    try {
      debugPrint('🔵 Handling failure URL: $url');
      final uri = Uri.parse(url);
      final message = uri.queryParameters['data.message'] ??
          uri.queryParameters['message'] ??
          'Payment failed';

      debugPrint('❌ Failure message: $message');

      widget.onPaymentComplete(PaymentResult.failure(message: message));
    } catch (e) {
      debugPrint('❌ Error handling failure: $e');
      widget.onPaymentComplete(PaymentResult.failure(
        message: 'Payment failed',
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRtl = context.locale.languageCode == 'ar';

    // Dynamic title based on payment type
    final title = widget.isWalletPayment
        ? (isRtl ? 'الدفع بالمحفظة' : 'Wallet Payment')
        : (isRtl ? 'الدفع بالبطاقة' : 'Card Payment');

    // On web, show a message that payment opened in browser
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(isRtl ? Icons.arrow_forward : Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.open_in_new,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                isRtl
                    ? 'تم فتح صفحة الدفع في نافذة جديدة'
                    : 'Payment page opened in new window',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  isRtl
                      ? 'يرجى إكمال عملية الدفع في النافذة الجديدة'
                      : 'Please complete the payment in the new window',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(isRtl ? Icons.arrow_forward : Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
            widget.onCancel();
          },
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (_controller != null) WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isRtl ? 'جاري تحميل صفحة الدفع...' : 'Loading...',
                      style: TextStyle(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_errorMessage != null && !_isLoading)
            Container(
              color: theme.scaffoldBackgroundColor,
              child: ErrorState(
                type: ErrorType.server,
                title: isRtl
                    ? 'فشل في تحميل صفحة الدفع'
                    : 'Failed to load payment page',
                message: _errorMessage!,
                onRetry: () {
                  setState(() {
                    _errorMessage = null;
                    _isLoading = true;
                  });
                  _controller?.loadRequest(Uri.parse(widget.paymentUrl));
                },
              ),
            ),
        ],
      ),
    );
  }
}
