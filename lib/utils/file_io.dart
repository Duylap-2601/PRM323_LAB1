import 'dart:io';

/// Ghi file tạm rồi đổi tên để tránh báo cáo bị cắt khi app đóng (plan §4).
Future<void> writeFileAtomically(String path, String content) async {
  final target = File(path);
  final tmp = File('$path.tmp.${DateTime.now().microsecondsSinceEpoch}');
  await tmp.writeAsString(content, flush: true);
  if (await target.exists()) await target.delete();
  await tmp.rename(path);
}

/// Chỉ cho phép HTTP(S); chặn local/private, kiểm tra lại redirect (plan §8).
bool isAllowedFetchUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
    return false;
  }
  final host = uri.host.toLowerCase().trim();
  if (host.isEmpty || host == 'localhost') return false;
  if (host.endsWith('.local') || host.endsWith('.internal')) return false;
  if (RegExp(r'^(10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.)').hasMatch(host)) {
    return false;
  }
  if (host == '127.0.0.1' || host == '0.0.0.0' || host == '[::1]') return false;
  return true;
}
