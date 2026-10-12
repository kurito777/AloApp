// Abre una URL en el navegador del sistema (Windows/macOS/Linux) sin plugins.
import 'dart:io';

Future<bool> openExternalUrl(String url) async {
  try {
    if (Platform.isWindows) {
      await Process.start('cmd', ['/c', 'start', '', url]);
    } else if (Platform.isMacOS) {
      await Process.start('open', [url]);
    } else {
      await Process.start('xdg-open', [url]);
    }
    return true;
  } catch (_) {
    return false;
  }
}
