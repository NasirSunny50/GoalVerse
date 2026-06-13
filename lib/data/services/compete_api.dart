import 'dart:convert';

import 'package:http/http.dart' as http;

/// Base URL of the GoalVerse backend. Override at build time with
/// `--dart-define=API_BASE=http://<host>:8787`. Defaults to localhost for
/// running the app on the same PC as the server (web / Windows desktop).
const String kApiBase =
    String.fromEnvironment('API_BASE', defaultValue: 'http://localhost:8787');

class ApiException implements Exception {
  ApiException(this.message, [this.status = 0]);
  final String message;
  final int status;
  @override
  String toString() => message;
}

/// Thin HTTP client for the GoalVerse competition backend.
class CompeteApi {
  CompeteApi({http.Client? client, String? base})
      : _client = client ?? http.Client(),
        _base = base ?? kApiBase;

  final http.Client _client;
  final String _base;

  Map<String, String> _headers(String? token) => {
        'content-type': 'application/json',
        if (token != null) 'authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body,
      {String? token}) async {
    final res = await _client
        .post(Uri.parse('$_base$path'),
            headers: _headers(token), body: jsonEncode(body))
        .timeout(const Duration(seconds: 12));
    return _decode(res);
  }

  Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> body,
      {required String token}) async {
    final res = await _client
        .put(Uri.parse('$_base$path'),
            headers: _headers(token), body: jsonEncode(body))
        .timeout(const Duration(seconds: 12));
    return _decode(res);
  }

  Future<Map<String, dynamic>> _get(String path, {String? token}) async {
    final res = await _client
        .get(Uri.parse('$_base$path'), headers: _headers(token))
        .timeout(const Duration(seconds: 12));
    return _decode(res);
  }

  Future<Map<String, dynamic>> _delete(String path,
      {required String token}) async {
    final res = await _client
        .delete(Uri.parse('$_base$path'), headers: _headers(token))
        .timeout(const Duration(seconds: 12));
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response', res.statusCode);
    }
    if (res.statusCode >= 400) {
      throw ApiException(
          json['error']?.toString() ?? 'Request failed', res.statusCode);
    }
    return json;
  }

  // ---- endpoints ----------------------------------------------------------

  Future<void> register(String name, String employeeId, String email,
          String password, String confirmPassword) =>
      _post('/auth/register', {
        'name': name,
        'employeeId': employeeId,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
      });

  Future<Map<String, dynamic>> verifyOtp(String email, String code) =>
      _post('/auth/verify-otp', {'email': email, 'code': code});

  Future<Map<String, dynamic>> login(String email, String password) =>
      _post('/auth/login', {'email': email, 'password': password});

  Future<Map<String, dynamic>> me(String token) => _get('/me', token: token);

  Future<Map<String, dynamic>> predictions(String token) =>
      _get('/predictions', token: token);

  Future<void> putMatchPrediction(
          String token, String matchId, Map<String, dynamic> body) =>
      _put('/predictions/match/$matchId', body, token: token);

  Future<void> putTournament(String token, Map<String, dynamic> body) =>
      _put('/predictions/tournament', body, token: token);

  Future<List<dynamic>> leaderboard(String period, {String? token}) async {
    final json = await _get('/leaderboard?period=$period', token: token);
    return (json['entries'] as List?) ?? const [];
  }

  /// The schedule, with admin-assigned knockout teams overlaid (public).
  Future<List<dynamic>> serverFixtures() async {
    final json = await _get('/fixtures');
    return (json['fixtures'] as List?) ?? const [];
  }

  // ---- admin --------------------------------------------------------------

  Future<List<dynamic>> adminResults(String token) async {
    final json = await _get('/admin/results', token: token);
    return (json['matches'] as List?) ?? const [];
  }

  Future<void> setMatchResult(
          String token, String matchId, Map<String, dynamic> body) =>
      _put('/admin/result/$matchId', body, token: token);

  Future<void> clearMatchResult(String token, String matchId) =>
      _delete('/admin/result/$matchId', token: token);

  void dispose() => _client.close();
}
