import 'package:web/web.dart' as web;

bool get canSaveFile => true;

Future<void> openUrl(String url) async {
  web.window.open(url, '_blank');
}

/// Hands the browser a file to keep, through a download link; on a phone the
/// calendar app then offers to import it.
Future<void> saveTextFile(String name, String mime, String content) async {
  final a = web.HTMLAnchorElement()
    ..href = 'data:$mime;charset=utf-8,${Uri.encodeComponent(content)}'
    ..download = name;
  web.document.body?.append(a);
  a.click();
  a.remove();
}
