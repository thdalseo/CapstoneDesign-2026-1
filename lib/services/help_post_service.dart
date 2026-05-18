import '../core/api_client.dart';

class HelpPostService {
  static const _base = '/api/help-posts';

  /// 전체 게시글 목록
  static Future<List<Map<String, dynamic>>> fetchPosts() async {
    final res = await ApiClient.get(_base);
    return (res['posts'] as List).cast<Map<String, dynamic>>();
  }

  /// 내 게시글 목록
  static Future<List<Map<String, dynamic>>> fetchMyPosts(String email) async {
    final res = await ApiClient.get('$_base/mine', params: {'email': email});
    return (res['posts'] as List).cast<Map<String, dynamic>>();
  }

  /// 게시글 작성
  static Future<Map<String, dynamic>> createPost({
    required String authorEmail,
    required String category,
    required String title,
    required String place,
    required String date, // "YYYY-MM-DD"
    required String time, // "HH:MM:00"
    String? memo,
    bool isUrgent = false,
  }) async {
    final res = await ApiClient.post(_base, {
      'author_email': authorEmail,
      'category': category,
      'title': title,
      'place': place,
      'date': date,
      'time': time,
      if (memo != null && memo.isNotEmpty) 'memo': memo,
      'is_urgent': isUrgent,
    });
    return res['post'] as Map<String, dynamic>;
  }

  /// 게시글 수정
  static Future<Map<String, dynamic>> updatePost(
    int id, {
    String? category,
    String? title,
    String? place,
    String? date,
    String? time,
    String? memo,
    bool? isUrgent,
  }) async {
    final body = <String, dynamic>{};
    if (category != null) body['category'] = category;
    if (title != null) body['title'] = title;
    if (place != null) body['place'] = place;
    if (date != null) body['date'] = date;
    if (time != null) body['time'] = time;
    if (memo != null) body['memo'] = memo;
    if (isUrgent != null) body['is_urgent'] = isUrgent;

    final res = await ApiClient.put('$_base/$id', body);
    return res['post'] as Map<String, dynamic>;
  }

  /// 게시글 완료 처리
  static Future<Map<String, dynamic>> completePost(int id) async {
    final res = await ApiClient.patch('$_base/$id/complete');
    return res['post'] as Map<String, dynamic>;
  }

  /// 게시글 삭제
  static Future<void> deletePost(int id) async {
    await ApiClient.delete('$_base/$id', {});
  }

  /// 도움 신청
  static Future<Map<String, dynamic>> applyHelp(
      int postId, String helperEmail) async {
    final res = await ApiClient.post('$_base/$postId/helpers', {
      'helper_email': helperEmail,
    });
    return res['post'] as Map<String, dynamic>;
  }
}
