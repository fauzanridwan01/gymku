import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Alamat API Laravel. Ganti sesuai tempat backend berjalan:
///  - Chrome / Windows / desktop : http://localhost:8000/api
///  - Emulator Android           : http://10.0.2.2:8000/api
///  - HP asli (satu Wi-Fi)       : http://<IP laptop>:8000/api
///  - Server produksi            : https://domain-anda.com/api
const String kApiBaseUrl = 'http://localhost:8000/api';

/// Error dari API dengan pesan yang siap ditampilkan ke pengguna.
class ApiException implements Exception {
  ApiException(this.message, {this.status});
  final String message;
  final int? status;

  bool get isUnauthorized => status == 401;
  bool get isNetwork => status == null;

  @override
  String toString() => message;
}

/// Klien HTTP tipis: menempelkan token Sanctum dan menerjemahkan error.
class ApiClient {
  static const _tokenKey = 'gymku_token';
  static const _timeout = Duration(seconds: 15);

  String? _token;
  String? get token => _token;
  bool get hasToken => _token != null && _token!.isNotEmpty;

  /// Muat token tersimpan (dipanggil sekali saat aplikasi mulai).
  Future<void> loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
    } catch (_) {
      _token = null;
    }
  }

  Future<void> setToken(String? value) async {
    _token = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value == null) {
        await prefs.remove(_tokenKey);
      } else {
        await prefs.setString(_tokenKey, value);
      }
    } catch (_) {
      // Penyimpanan gagal: token tetap dipakai selama aplikasi terbuka.
    }
  }

  Future<Map<String, dynamic>> get(String path) => _send('GET', path);

  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) =>
      _send('POST', path, body);

  /// Keluar di server lalu hapus token lokal. Tidak pernah melempar error.
  Future<void> logout() async {
    final hadToken = hasToken;
    try {
      if (hadToken) await _send('POST', '/auth/logout');
    } catch (_) {
      // Token lokal tetap dihapus walau server tidak terjangkau.
    }
    await setToken(null);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final uri = Uri.parse('$kApiBaseUrl$path');
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (hasToken) 'Authorization': 'Bearer $_token',
    };

    final http.Response res;
    try {
      final req = method == 'GET'
          ? http.get(uri, headers: headers)
          : http.post(uri, headers: headers, body: jsonEncode(body ?? {}));
      res = await req.timeout(_timeout);
    } on TimeoutException {
      throw ApiException('Server tidak merespons. Coba lagi sebentar lagi.');
    } catch (_) {
      throw ApiException(
        'Tidak dapat terhubung ke server. Pastikan backend sedang berjalan.',
      );
    }

    Map<String, dynamic> json = {};
    if (res.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) json = decoded;
      } catch (_) {
        // Balasan bukan JSON (mis. halaman error): ditangani di bawah.
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return json;
    throw ApiException(_messageFrom(res.statusCode, json), status: res.statusCode);
  }

  /// Ambil pesan error pertama dari balasan Laravel (422 berisi `errors`).
  String _messageFrom(int status, Map<String, dynamic> json) {
    final errors = json['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return '${first.first}';
      if (first != null) return '$first';
    }
    final message = json['message'];
    if (message is String && message.isNotEmpty) {
      if (status == 401) return 'Sesi berakhir. Silakan login lagi.';
      return message;
    }
    if (status == 401) return 'Sesi berakhir. Silakan login lagi.';
    if (status >= 500) return 'Terjadi kesalahan di server. Coba lagi nanti.';
    return 'Permintaan gagal (kode $status).';
  }
}
