// lib/services/farming_tip_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FarmingTipService {
  static const String baseUrl = 'https://agriguide-backend-79j2.onrender.com';

  static const String _cacheKeyPrefix = 'cached_farming_tip';
  static const String _cacheDateKey = 'cached_tip_date';
  static const String _cacheLanguageKey = 'cached_tip_language';

  /// Fetch daily farming tip from backend
  /// [language] - 'english' or 'sesotho'
  Future<Map<String, dynamic>> getDailyFarmingTip(
    String token, {
    String language = 'english',
  }) async {
    try {
      // Check cache first (with language)
      final cachedTip = await _getCachedTip(language);
      if (cachedTip != null) {
        return cachedTip;
      }

      // Fetch from API with language parameter
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/farming-tip/?language=$language'),
            headers: {
              'Authorization': 'Token $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Cache the tip with language
        await _cacheTip(data, language);

        return {
          'success': true,
          'tip': data['tip'],
          'cached': data['cached'] ?? false,
          'fallback': data['fallback'] ?? false,
          'language': data['language'] ?? language,
          'date': data['date'],
        };
      } else {
        throw Exception('Failed to load farming tip: ${response.statusCode}');
      }
    } catch (e) {
      // Return cached tip if available, otherwise return default
      final cachedTip = await _getCachedTip(language);
      if (cachedTip != null) {
        return {...cachedTip, 'error': true, 'errorMessage': e.toString()};
      }

      // Return default fallback tip in the requested language
      return {
        'success': false,
        'tip': _getDefaultFallbackTip(language),
        'fallback': true,
        'language': language,
        'error': true,
        'errorMessage': e.toString(),
      };
    }
  }

  /// Get cached tip from local storage (language-specific)
  Future<Map<String, dynamic>?> _getCachedTip(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cacheKeyPrefix}_$language';
      final cachedTip = prefs.getString(cacheKey);
      final cachedDate = prefs.getString(_cacheDateKey);
      final cachedLanguage = prefs.getString(_cacheLanguageKey);

      if (cachedTip != null && 
          cachedDate != null && 
          cachedLanguage == language) {
        // Check if cache is from today or yesterday (within 2 days)
        final cacheDateTime = DateTime.parse(cachedDate);
        final todayDateTime = DateTime.now();
        final difference = todayDateTime.difference(cacheDateTime).inDays;

        if (difference <= 1) {
          return {
            'success': true,
            'tip': cachedTip,
            'cached': true,
            'language': cachedLanguage,
            'date': cachedDate,
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cache tip to local storage with language
  Future<void> _cacheTip(Map<String, dynamic> data, String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cacheKeyPrefix}_$language';
      await prefs.setString(cacheKey, data['tip']);
      await prefs.setString(_cacheDateKey, data['date']);
      await prefs.setString(_cacheLanguageKey, language);
    } catch (e) {
      // Silently fail - caching is not critical
    }
  }

  /// Get default fallback tip based on language
  String _getDefaultFallbackTip(String language) {
    final englishTips = [
      "Water your plants early in the morning to reduce water loss through evaporation. This also helps prevent fungal diseases that thrive in moist conditions during cooler evening hours.",
      "Rotate your crops each season to prevent soil nutrient depletion and reduce pest buildup. For example, follow nitrogen-fixing legumes with heavy feeders like corn or tomatoes.",
      "Apply mulch around your plants to retain soil moisture, regulate temperature, and suppress weeds. Organic mulches also improve soil health as they decompose.",
      "Monitor your crops regularly for early signs of pests or diseases. Early detection allows for quicker intervention and prevents widespread damage to your harvest.",
      "Test your soil pH annually to ensure optimal nutrient availability. Most crops thrive in slightly acidic to neutral soil (pH 6.0-7.0).",
    ];

    final sesothoTips = [
      "Nosetsa dimela tsa hao hoseng ho hoseng ho fokotsa tahlehelo ea metsi ka ho fetoha mouoane. Sena se thusa hape ho thibela mafu a fungal a atang maemong a mongobo nakong ea mantsiboya a batang.",
      "Feto-fetoha lijalo tsa hao sehla se seng le se seng ho thibela ho fella ha limatlafatsi tsa mobu le ho eketseha ha likokoanyana. Mohlala, latela linaoa tse matlafatsang nitrogen ka lijalo tse jang haholo joalo ka poone kapa tamati.",
      "Kenya mulch ho potoloha dimela tsa hao ho boloka mongobo oa mobu, ho laola thempereichara le ho thibela joang. Li-mulch tsa tlhaho li boetse li ntlafatsa bophelo bo botle ba mobu ha li bola.",
      "Hlahloba lijalo tsa hao kamehla ho bona matšoao a pele a likokoanyana kapa mafu. Phihlello ea pele e lumella ho kena ka potlako le ho thibela tšenyo e pharaletseng ho kotulo ea hau.",
      "Lekola pH ea mobu oa hao selemo le selemo ho netefatsa ho fumaneha ha limatlafatsi hantle. Lijalo tse ngata li ata mabung a nang le asiti e fokolang ho ea ho neutral (pH 6.0-7.0).",
    ];

    final tips = language == 'sesotho' ? sesothoTips : englishTips;

    // Return random tip
    return tips[DateTime.now().day % tips.length];
  }

  /// Clear cached tip for specific language (useful for testing)
  Future<void> clearCache({String? language}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (language != null) {
        // Clear specific language cache
        final cacheKey = '${_cacheKeyPrefix}_$language';
        await prefs.remove(cacheKey);
      } else {
        // Clear all language caches
        await prefs.remove('${_cacheKeyPrefix}_english');
        await prefs.remove('${_cacheKeyPrefix}_sesotho');
      }
      await prefs.remove(_cacheDateKey);
      await prefs.remove(_cacheLanguageKey);
    } catch (e) {
      // Silently fail
    }
  }
}