import 'package:url_launcher/url_launcher.dart';

bool get canSaveFile => false;

Future<void> openUrl(String url) async {
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

Future<void> saveTextFile(String name, String mime, String content) async {}
