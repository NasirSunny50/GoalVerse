import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
};

Response jsonResponse(Object? data, {int status = 200}) => Response(
      status,
      body: jsonEncode(data),
      headers: {'content-type': 'application/json', ..._corsHeaders},
    );

Response jsonError(String message, {int status = 400}) =>
    jsonResponse({'error': message}, status: status);

/// Adds CORS headers and short-circuits pre-flight OPTIONS requests.
Middleware corsMiddleware() => (handler) => (req) async {
      if (req.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }
      final res = await handler(req);
      return res.change(headers: _corsHeaders);
    };

final _rng = Random.secure();

String genSalt() =>
    base64Url.encode(List.generate(16, (_) => _rng.nextInt(256)));

String genToken() =>
    base64Url.encode(List.generate(32, (_) => _rng.nextInt(256)));

String hashPassword(String pw, String salt) =>
    sha256.convert(utf8.encode('$salt|$pw')).toString();

bool isValidEmail(String s) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);

Future<Map<String, dynamic>> readJsonBody(Request req) async {
  final body = await req.readAsString();
  if (body.isEmpty) return {};
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Expected a JSON object');
  }
  return decoded;
}
