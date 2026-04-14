import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'auth_service.dart';

/// A detected subscription from Gmail parsing.
class DetectedSubscription {
  final String name;
  String price;
  final String category;
  final String date;
  final String emailSubject;
  bool selected;

  DetectedSubscription({
    required this.name,
    required this.price,
    required this.category,
    required this.date,
    required this.emailSubject,
    this.selected = true,
  });

  Subscription toSubscription() => Subscription(
        name: name,
        price: price,
        nextBilling: date,
        category: category,
        isActive: true,
      );
}

class GmailService {
  static const String _baseUrl = 'https://gmail.googleapis.com/gmail/v1/users/me';
  final AuthService _authService = AuthService();

  // ─── Known services with patterns AND estimated prices ───
  static final List<_ServicePattern> _servicePatterns = [
    // Entertainment
    _ServicePattern('Netflix', ['netflix'], 'Entertainment', '₹199/mo'),
    _ServicePattern('Spotify', ['spotify'], 'Entertainment', '₹119/mo'),
    _ServicePattern('Amazon Prime', ['amazon prime', 'prime video', 'prime membership'], 'Entertainment', '₹1,499/yr'),
    _ServicePattern('Disney+ Hotstar', ['disney+', 'hotstar', 'disney plus'], 'Entertainment', '₹299/mo'),
    _ServicePattern('YouTube Premium', ['youtube premium', 'youtube music'], 'Entertainment', '₹149/mo'),
    _ServicePattern('Apple TV+', ['apple tv'], 'Entertainment', '₹99/mo'),
    _ServicePattern('JioCinema', ['jiocinema'], 'Entertainment', '₹29/mo'),
    _ServicePattern('SonyLIV', ['sonyliv'], 'Entertainment', '₹299/mo'),
    _ServicePattern('ZEE5', ['zee5'], 'Entertainment', '₹99/mo'),
    _ServicePattern('Crunchyroll', ['crunchyroll'], 'Entertainment', '\$7.99/mo'),
    _ServicePattern('HBO Max', ['hbo max', 'hbo'], 'Entertainment', '\$15.99/mo'),
    _ServicePattern('Xbox Game Pass', ['xbox game pass', 'game pass'], 'Entertainment', '₹499/mo'),
    _ServicePattern('PlayStation Plus', ['playstation plus', 'ps plus'], 'Entertainment', '₹3,499/yr'),
    _ServicePattern('Nintendo Online', ['nintendo switch online'], 'Entertainment', '₹1,749/yr'),

    // Music
    _ServicePattern('Apple Music', ['apple music'], 'Music', '₹99/mo'),
    _ServicePattern('Gaana', ['gaana'], 'Music', '₹99/mo'),
    _ServicePattern('JioSaavn', ['jiosaavn', 'saavn'], 'Music', '₹99/mo'),
    _ServicePattern('Wynk Music', ['wynk'], 'Music', '₹49/mo'),

    // Productivity
    _ServicePattern('Microsoft 365', ['microsoft 365', 'office 365', 'microsoft subscription'], 'Productivity', '₹489/mo'),
    _ServicePattern('Google One', ['google one', 'google storage'], 'Productivity', '₹130/mo'),
    _ServicePattern('Notion', ['notion'], 'Productivity', '\$10/mo'),
    _ServicePattern('Slack', ['slack'], 'Productivity', '\$8.75/mo'),
    _ServicePattern('Zoom', ['zoom'], 'Productivity', '₹1,100/mo'),
    _ServicePattern('Canva Pro', ['canva'], 'Productivity', '₹500/mo'),
    _ServicePattern('ChatGPT Plus', ['chatgpt', 'openai'], 'Productivity', '\$20/mo'),
    _ServicePattern('GitHub', ['github'], 'Productivity', '\$4/mo'),

    // Cloud
    _ServicePattern('Adobe Creative Cloud', ['adobe', 'creative cloud'], 'Cloud', '₹1,675/mo'),
    _ServicePattern('Dropbox', ['dropbox'], 'Cloud', '₹790/mo'),
    _ServicePattern('iCloud', ['icloud'], 'Cloud', '₹75/mo'),
    _ServicePattern('AWS', ['amazon web services', 'aws'], 'Cloud', ''),

    // Other
    _ServicePattern('Swiggy One', ['swiggy one', 'swiggy super'], 'Other', '₹299/3mo'),
    _ServicePattern('Zomato Gold', ['zomato gold', 'zomato pro'], 'Other', '₹300/3mo'),
    _ServicePattern('LinkedIn Premium', ['linkedin premium'], 'Other', '₹1,555/mo'),
    _ServicePattern('Medium', ['medium membership', 'medium subscription'], 'Other', '\$5/mo'),
    _ServicePattern('Audible', ['audible'], 'Other', '₹199/mo'),
    _ServicePattern('Kindle Unlimited', ['kindle unlimited'], 'Other', '₹169/mo'),
  ];

  // ─── Price patterns (₹, $, Rs, INR, USD) ───
  static final RegExp _priceRegex = RegExp(
    r'(?:₹|Rs\.?\s*|INR\s*|USD\s*|\$)\s*[\d,]+(?:\.\d{1,2})?'
    r'|[\d,]+(?:\.\d{1,2})?\s*(?:₹|Rs\.?|INR|USD|\$)',
    caseSensitive: false,
  );

  /// Fetch and parse subscription emails from the last 6 months.
  Future<List<DetectedSubscription>> scanForSubscriptions() async {
    final accessToken = await _authService.getGmailAccessToken();
    if (accessToken == null) {
      throw Exception('Please sign in with Google and grant Gmail access to scan your inbox');
    }

    final headers = {'Authorization': 'Bearer $accessToken'};

    // Search for subscription-related emails from last 6 months
    final query = Uri.encodeComponent(
      '(subject:subscription OR subject:renewal OR subject:billing '
      'OR subject:payment OR subject:invoice OR subject:receipt '
      'OR subject:"your plan" OR subject:"membership" '
      'OR subject:"order confirmation" OR subject:"auto-renewal" '
      'OR from:netflix OR from:spotify OR from:primevideo '
      'OR from:hotstar OR from:youtube OR from:apple '
      'OR from:google OR from:microsoft OR from:adobe '
      'OR from:chatgpt OR from:openai OR from:canva '
      'OR from:swiggy OR from:zomato OR from:linkedin) '
      'newer_than:6m',
    );

    final listUrl = '$_baseUrl/messages?q=$query&maxResults=100';
    final listResponse = await http.get(Uri.parse(listUrl), headers: headers);

    if (listResponse.statusCode != 200) {
      throw Exception('Failed to fetch emails: ${listResponse.statusCode}');
    }

    final listBody = jsonDecode(listResponse.body) as Map<String, dynamic>;
    final messages = listBody['messages'] as List<dynamic>? ?? [];

    if (messages.isEmpty) return [];

    // Fetch each message (subject, date, snippet + body) in parallel
    // Limit to 50 to avoid rate limiting
    final messagesToFetch = messages.take(50).toList();
    final futures = messagesToFetch.map((msg) async {
      final id = msg['id'] as String;
      // Use 'full' format to get the body for price extraction
      final url = '$_baseUrl/messages/$id?format=full';
      try {
        final resp = await http.get(Uri.parse(url), headers: headers);
        if (resp.statusCode == 200) {
          return jsonDecode(resp.body) as Map<String, dynamic>;
        }
      } catch (_) {}
      return null;
    });

    final results = await Future.wait(futures);
    final detectedMap = <String, DetectedSubscription>{};

    for (final msgData in results) {
      if (msgData == null) continue;

      final payloadHeaders = (msgData['payload']?['headers'] as List<dynamic>?) ?? [];
      String subject = '';
      String date = '';

      for (final header in payloadHeaders) {
        final name = header['name'] as String? ?? '';
        if (name == 'Subject') subject = header['value'] ?? '';
        if (name == 'Date') date = header['value'] ?? '';
      }

      final snippet = msgData['snippet'] as String? ?? '';
      
      // Extract body text for price detection
      final bodyText = _extractBodyText(msgData['payload']);
      
      final searchText = '$subject $snippet $bodyText'.toLowerCase();

      // Match against known services
      for (final pattern in _servicePatterns) {
        if (pattern.matches(searchText) && !detectedMap.containsKey(pattern.name)) {
          // Try to extract price from subject, snippet, then body
          String price = _extractPrice(subject);
          if (price.isEmpty) price = _extractPrice(snippet);
          if (price.isEmpty) price = _extractPrice(bodyText);
          // Fall back to known default price
          if (price.isEmpty) price = pattern.defaultPrice;

          final parsedDate = _parseEmailDate(date);

          detectedMap[pattern.name] = DetectedSubscription(
            name: pattern.name,
            price: price,
            category: pattern.category,
            date: parsedDate,
            emailSubject: subject,
          );
          break;
        }
      }
    }

    final detected = detectedMap.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return detected;
  }

  /// Extract readable text from email payload (handles multipart).
  String _extractBodyText(Map<String, dynamic>? payload) {
    if (payload == null) return '';
    
    // Try direct body
    final body = payload['body'] as Map<String, dynamic>?;
    if (body != null && body['data'] != null) {
      try {
        final decoded = utf8.decode(base64Url.decode(body['data'] as String));
        // Strip HTML tags for cleaner text
        return decoded.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ');
      } catch (_) {}
    }

    // Try multipart parts
    final parts = payload['parts'] as List<dynamic>?;
    if (parts != null) {
      for (final part in parts) {
        final mimeType = part['mimeType'] as String? ?? '';
        if (mimeType == 'text/plain' || mimeType == 'text/html') {
          final partBody = part['body'] as Map<String, dynamic>?;
          if (partBody != null && partBody['data'] != null) {
            try {
              final decoded = utf8.decode(base64Url.decode(partBody['data'] as String));
              final text = decoded.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ');
              // Only return first 2000 chars to keep it efficient
              return text.length > 2000 ? text.substring(0, 2000) : text;
            } catch (_) {}
          }
        }
        // Check nested parts (e.g., multipart/alternative inside multipart/mixed)
        if (part['parts'] != null) {
          final nested = _extractBodyText(part as Map<String, dynamic>);
          if (nested.isNotEmpty) return nested;
        }
      }
    }
    
    return '';
  }

  /// Extract price from text.
  String _extractPrice(String text) {
    if (text.isEmpty) return '';
    final match = _priceRegex.firstMatch(text);
    if (match != null) {
      return match.group(0)!.trim();
    }
    return '';
  }

  /// Parse email date header into a readable format.
  String _parseEmailDate(String dateStr) {
    try {
      final cleaned = dateStr.replaceAll(RegExp(r'\s+\(.*\)$'), '').trim();
      final parts = cleaned.split(RegExp(r'[\s,]+'));
      if (parts.length >= 4) {
        String? day, month, year;
        final months = {
          'jan': 'Jan', 'feb': 'Feb', 'mar': 'Mar', 'apr': 'Apr',
          'may': 'May', 'jun': 'Jun', 'jul': 'Jul', 'aug': 'Aug',
          'sep': 'Sep', 'oct': 'Oct', 'nov': 'Nov', 'dec': 'Dec',
        };

        for (final part in parts) {
          final lower = part.toLowerCase();
          if (months.containsKey(lower)) {
            month = months[lower];
          } else if (RegExp(r'^\d{4}$').hasMatch(part)) {
            year = part;
          } else if (RegExp(r'^\d{1,2}$').hasMatch(part)) {
            day = part.padLeft(2, '0');
          }
        }

        if (day != null && month != null && year != null) {
          return '$month $day, $year';
        }
      }
    } catch (_) {}
    return '';
  }
}

class _ServicePattern {
  final String name;
  final List<String> keywords;
  final String category;
  final String defaultPrice;

  const _ServicePattern(this.name, this.keywords, this.category, this.defaultPrice);

  bool matches(String text) {
    return keywords.any((kw) => text.contains(kw));
  }
}
