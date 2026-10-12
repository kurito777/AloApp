// Abre una URL en el navegador (web) sin dependencias externas.
import 'dart:html' as html;

Future<bool> openExternalUrl(String url) async {
  html.window.open(url, '_blank');
  return true;
}
