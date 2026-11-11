import 'dart:io';

/// Open a trusted HTTPS URL in the Windows default browser without a plugin.
Future<bool> launchUrl(Uri uri) async {
  if (uri.scheme != 'https') return false;
  final result = await Process.run('rundll32.exe', [
    'url.dll,FileProtocolHandler',
    uri.toString(),
  ], runInShell: false);
  return result.exitCode == 0;
}
