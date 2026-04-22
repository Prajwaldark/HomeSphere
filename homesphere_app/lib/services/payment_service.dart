import 'package:url_launcher/url_launcher.dart';

class PaymentResult {
  final bool success;
  final String? error;

  PaymentResult({required this.success, this.error});
}

class PaymentService {
  static final RegExp _upiIdRegex = RegExp(
    r'^[a-zA-Z0-9._%-]+@[a-zA-Z]{2,}$',
  );

  static String? validateUpiId(String upiId) {
    final trimmed = upiId.trim();
    if (trimmed.isEmpty) {
      return 'UPI ID is required';
    }
    if (!_upiIdRegex.hasMatch(trimmed)) {
      return 'Invalid UPI ID format (e.g., merchant@upi)';
    }
    return null;
  }

  static String parseAmount(String price) {
    // Remove currency symbols, commas, and billing cycle suffixes
    final cleaned = price
        .replaceAll(RegExp(r'[₹$€£]'), '')
        .replaceAll(RegExp(r','), '')
        .replaceAll(RegExp(r'\s*(?:/mo|/month|/yr|/year|/yr|/mo)\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'[^0-9.]'), '');
    
    // Handle edge cases
    if (cleaned.isEmpty || cleaned == '.') {
      return '0';
    }
    
    // Take only the first numeric value if there are multiple
    final match = RegExp(r'^[\d.]+').firstMatch(cleaned);
    return match?.group(0) ?? '0';
  }

  /// Launches the user's installed UPI app with the provided details.
  /// Returns a [PaymentResult] with success status and error message if failed.
  static Future<PaymentResult> launchUPI({
    required String upiId,
    required String payeeName,
    required String amount,
    String transactionNote = 'Subscription Payment',
  }) async {
    // Validate UPI ID first
    final validationError = validateUpiId(upiId);
    if (validationError != null) {
      return PaymentResult(success: false, error: validationError);
    }

    // Validate amount
    final parsedAmount = parseAmount(amount);
    if (parsedAmount == '0' || parsedAmount.isEmpty) {
      return PaymentResult(success: false, error: 'Invalid amount');
    }

    // Construct the UPI intent URL
    final String url =
        'upi://pay?pa=${Uri.encodeComponent(upiId.trim())}&pn=${Uri.encodeComponent(payeeName)}&am=$parsedAmount&cu=INR&tn=${Uri.encodeComponent(transactionNote)}';
    
    final Uri uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (launched) {
          return PaymentResult(success: true);
        } else {
          return PaymentResult(
            success: false,
            error: 'Could not launch UPI app. Is it installed?',
          );
        }
      } else {
        return PaymentResult(
          success: false,
          error: 'No UPI app found. Please install GPay, PhonePe, or Paytm.',
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        error: 'Payment error: ${e.toString()}',
      );
    }
  }
}
