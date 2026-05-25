import '../core/api_client.dart';

/// 번역 서비스

class TranslationService {
  /// [text] 를 [targetLang] 언어로 번역해 반환.
  /// targetLang: 'ko' | 'en' | 'ja' | 'zh' | ...
  static Future<String> translate(
    String text, {
    String targetLang = 'ko',
  }) async {
    if (text.trim().isEmpty) return text;

    final res = await ApiClient.post('/api/translate', {
      'text': text,
      'target_lang': targetLang,
    });

    return res['translated_text'] as String? ?? text;
  }
}
