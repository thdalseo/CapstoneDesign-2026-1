/// 번역 서비스

class TranslationService {
  /// [text] 를 [targetLang] 언어로 번역해 반환.
  /// targetLang: 'ko' | 'en' | 'ja' | 'zh' | ...
  static Future<String> translate(
    String text, {
    String targetLang = 'ko',
  }) async {
    if (text.trim().isEmpty) return text;

    // ── 실제 API 연동 시 아래 주석 해제 ──────────────────────────────────────
    //
    // [Papago 예시]
    // final res = await http.post(
    //   Uri.parse('https://openapi.naver.com/v1/papago/n2mt'),
    //   headers: {
    //     'X-Naver-Client-Id': 'YOUR_CLIENT_ID',
    //     'X-Naver-Client-Secret': 'YOUR_CLIENT_SECRET',
    //     'Content-Type': 'application/x-www-form-urlencoded',
    //   },
    //   body: 'source=auto&target=$targetLang&text=${Uri.encodeComponent(text)}',
    // );
    // final json = jsonDecode(res.body);
    // return json['message']['result']['translatedText'] as String;
    //
    // [DeepL 예시]
    // final res = await http.post(
    //   Uri.parse('https://api-free.deepl.com/v2/translate'),
    //   headers: {'Authorization': 'DeepL-Auth-Key YOUR_KEY'},
    //   body: {'text': text, 'target_lang': targetLang.toUpperCase()},
    // );
    // final json = jsonDecode(res.body);
    // return json['translations'][0]['text'] as String;
    //
    // ─────────────────────────────────────────────────────────────────────────

    // Mock: 500ms 지연 후 원문 반환 (API 미연동 표시)
    await Future.delayed(const Duration(milliseconds: 500));
    return '[$targetLang 번역 예정]\n$text';
  }
}
