import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final client = HttpClient();
  final request = await client.postUrl(Uri.parse('http://localhost:8080/b1s/v1/Login'));
  request.headers.set('Content-Type', 'application/json');
  request.write(jsonEncode({
    'CompanyDB': 'ZTEST_AR_TRIBUTARIO',
    'UserName': 'INDACC02',
    'Password': 'TestIC2024',
    'Language': 25,
  }));
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  print('Status: ${response.statusCode}');
  print('Body: $body');
}