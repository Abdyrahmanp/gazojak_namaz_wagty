import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// byethost3.com hosting'nin AES-128-CBC anti-bot challenge'ını saf Dart ile çözen HTTP client.
///
/// byethost şu akışı uygular:
///   1. İlk GET isteği → HTML + JS (AES şifreli cookie challenge)
///   2. JS içinden: __test = slowAES.decrypt(c, 2, a, b) → cookie olarak set et
///   3. ?i=1 ile ikinci GET isteği (cookie dahil) → gerçek içerik
class BytehostHttpClient {
  static const String _userAgent =
      'Mozilla/5.0 (Linux; Android 10; SM-G973F) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';

  /// Verilen URL'den JSON string alır. byethost challenge'ını otomatik çözer.
  /// Başarısızlıkta null döner.
  static Future<String?> fetchJson(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 25);
      // SSL sertifika hatalarını yoksay (byethost bazen self-signed kullanır)
      client.badCertificateCallback = (cert, host, port) => true;

      // ── ADIM 1: İlk istek → challenge HTML al ──────────────────────────────
      final req1 = await client.getUrl(uri);
      req1.headers.set('User-Agent', _userAgent);
      req1.headers.set('Accept', 'application/json,text/html,*/*');
      req1.headers.set('Accept-Language', 'tr,en;q=0.9');
      req1.headers.set('Connection', 'keep-alive');

      final res1 = await req1.close();
      final body1 = await res1.transform(utf8.decoder).join();

      String? cookieValue;
      String? redirectUrl;

      // ── ADIM 2: HTML'de AES challenge var mı? ──────────────────────────────
      if (body1.contains('slowAES') || body1.contains('__test')) {
        final solved = _solveAesChallenge(body1, uri);
        if (solved != null) {
          cookieValue = solved.cookie;
          redirectUrl = solved.redirectUrl;
        }
      } else if (res1.statusCode == 200 && _isValidJson(body1)) {
        // Challenge yok, direkt JSON geldi
        client.close();
        return body1;
      }

      if (cookieValue == null) {
        // Challenge çözülemediyse veya challenge yoksa ama JSON da değilse
        client.close();
        return null;
      }

      // ── ADIM 3: Cookie ile ikinci istek ─────────────────────────────────────
      final targetUrl = redirectUrl != null
          ? Uri.parse(redirectUrl)
          : uri.replace(queryParameters: {...uri.queryParameters, 'i': '1'});

      final req2 = await client.getUrl(targetUrl);
      req2.headers.set('User-Agent', _userAgent);
      req2.headers.set('Accept', 'application/json,text/html,*/*');
      req2.headers.set('Accept-Language', 'tr,en;q=0.9');
      req2.headers.set('Connection', 'keep-alive');
      req2.headers.set('Cookie', '__test=$cookieValue');
      req2.headers.set('Referer', uri.toString());

      final res2 = await req2.close();
      final body2 = await res2.transform(utf8.decoder).join();

      client.close();

      // Bazı durumlarda bir challenge daha gelir (i=2)
      if ((body2.contains('slowAES') || body2.contains('__test')) &&
          !_isValidJson(body2)) {
        final solved2 = _solveAesChallenge(body2, targetUrl);
        if (solved2 != null) {
          return await _thirdRequest(
              urlString, solved2.cookie, solved2.redirectUrl);
        }
        return null;
      }

      if (res2.statusCode == 200 && _isValidJson(body2)) {
        return body2;
      }

      return null;
    } catch (e) {
      // ignore: avoid_print
      print('[BytehostHttpClient] fetchJson error: $e');
      return null;
    }
  }

  static Future<String?> _thirdRequest(
      String originalUrl, String cookieValue, String? redirectUrl) async {
    try {
      final uri = Uri.parse(originalUrl);
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 25);
      client.badCertificateCallback = (cert, host, port) => true;

      final targetUrl = redirectUrl != null
          ? Uri.parse(redirectUrl)
          : uri.replace(queryParameters: {...uri.queryParameters, 'i': '2'});

      final req = await client.getUrl(targetUrl);
      req.headers.set('User-Agent', _userAgent);
      req.headers.set('Accept', 'application/json,*/*');
      req.headers.set('Cookie', '__test=$cookieValue');
      req.headers.set('Referer', uri.toString());

      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      client.close();

      return _isValidJson(body) ? body : null;
    } catch (e) {
      // ignore: avoid_print
      print('[BytehostHttpClient] thirdRequest error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // AES Challenge Çözücü
  // ─────────────────────────────────────────────────────────────────────────────

  static _ChallengeSolution? _solveAesChallenge(String html, Uri baseUri) {
    try {
      // toNumbers("HEX") çağrılarını yakala
      final hexPattern = RegExp(r'toNumbers\("([0-9a-fA-F]+)"\)');
      final matches = hexPattern.allMatches(html).toList();
      if (matches.length < 3) return null;

      final keyHex = matches[0].group(1)!;
      final ivHex = matches[1].group(1)!;
      final cipherHex = matches[2].group(1)!;

      final key = _hexToBytes(keyHex);
      final iv = _hexToBytes(ivHex);
      final cipher = _hexToBytes(cipherHex);

      // AES-128-CBC ile decrypt et
      final decrypted = _aes128CbcDecrypt(cipher, key, iv);
      final cookieValue = _bytesToHex(decrypted);

      // location.href değerini yakala
      final hrefMatch =
          RegExp(r'location\.href="([^"]+)"').firstMatch(html);
      String? redirectUrl;
      if (hrefMatch != null) {
        final href = hrefMatch.group(1)!;
        if (href.startsWith('http')) {
          redirectUrl = href;
        } else {
          redirectUrl = '${baseUri.scheme}://${baseUri.host}$href';
        }
      }

      return _ChallengeSolution(cookieValue, redirectUrl);
    } catch (e) {
      // ignore: avoid_print
      print('[BytehostHttpClient] AES solve error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Saf Dart AES-128-CBC Implementasyonu
  // slowAES.js ile birebir uyumlu (CBC mode = 2)
  // ─────────────────────────────────────────────────────────────────────────────

  static Uint8List _aes128CbcDecrypt(
      Uint8List ciphertext, Uint8List key, Uint8List iv) {
    // AES key schedule
    final roundKeys = _keyExpansion(key);

    // CBC: her bloğu decrypt et, önceki şifreli blok ile XOR yap
    final blockCount = (ciphertext.length / 16).ceil();
    final result = Uint8List(ciphertext.length);

    for (int b = 0; b < blockCount; b++) {
      final start = b * 16;
      final end = (start + 16).clamp(0, ciphertext.length);
      final block = Uint8List(16);
      block.setRange(0, end - start, ciphertext, start);

      final decBlock = _aesDecryptBlock(block, roundKeys);

      // XOR with previous ciphertext block (or IV for first block)
      final prev = b == 0 ? iv : ciphertext.sublist((b - 1) * 16, b * 16);
      for (int i = 0; i < (end - start); i++) {
        result[start + i] = decBlock[i] ^ prev[i];
      }
    }
    return result;
  }

  static Uint8List _aesDecryptBlock(Uint8List block, List<Uint8List> roundKeys) {
    // Column-major state filling (AES FIPS 197 & slowAES.js compatible)
    // block[c*4+r] → state[r][c]
    final state = List.generate(4, (r) => List.generate(4, (c) => block[c * 4 + r]));

    _addRoundKey(state, roundKeys[10]);
    for (int round = 9; round >= 1; round--) {
      _invShiftRows(state);
      _invSubBytes(state);
      _addRoundKey(state, roundKeys[round]);
      _invMixColumns(state);
    }
    _invShiftRows(state);
    _invSubBytes(state);
    _addRoundKey(state, roundKeys[0]);

    // Column-major output: state[r][c] → output[c*4+r]
    final output = Uint8List(16);
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        output[c * 4 + r] = state[r][c];
      }
    }
    return output;
  }

  static void _addRoundKey(List<List<int>> state, Uint8List roundKey) {
    // Column-major: roundKey word c is at bytes c*4..c*4+3
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        state[r][c] ^= roundKey[c * 4 + r];
      }
    }
  }

  static void _invSubBytes(List<List<int>> state) {
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        state[r][c] = _invSBox[state[r][c]];
      }
    }
  }

  static void _invShiftRows(List<List<int>> state) {
    // Row 1: shift right by 1
    final t1 = state[1][3];
    state[1][3] = state[1][2];
    state[1][2] = state[1][1];
    state[1][1] = state[1][0];
    state[1][0] = t1;
    // Row 2: shift right by 2
    int tmp = state[2][0]; state[2][0] = state[2][2]; state[2][2] = tmp;
    tmp = state[2][1]; state[2][1] = state[2][3]; state[2][3] = tmp;
    // Row 3: shift right by 3 (= left by 1)
    final t3 = state[3][0];
    state[3][0] = state[3][1];
    state[3][1] = state[3][2];
    state[3][2] = state[3][3];
    state[3][3] = t3;
  }

  static void _invMixColumns(List<List<int>> state) {
    for (int c = 0; c < 4; c++) {
      final s0 = state[0][c];
      final s1 = state[1][c];
      final s2 = state[2][c];
      final s3 = state[3][c];
      state[0][c] = _gf(_e, s0) ^ _gf(_b, s1) ^ _gf(_d, s2) ^ _gf(_gfNine, s3);
      state[1][c] = _gf(_gfNine, s0) ^ _gf(_e, s1) ^ _gf(_b, s2) ^ _gf(_d, s3);
      state[2][c] = _gf(_d, s0) ^ _gf(_gfNine, s1) ^ _gf(_e, s2) ^ _gf(_b, s3);
      state[3][c] = _gf(_b, s0) ^ _gf(_d, s1) ^ _gf(_gfNine, s2) ^ _gf(_e, s3);
    }
  }

  // GF(2^8) çarpma
  static int _gf(int a, int b) {
    int p = 0;
    for (int i = 0; i < 8; i++) {
      if (b & 1 != 0) { p ^= a; }
      final hiBit = a & 0x80;
      a = (a << 1) & 0xFF;
      if (hiBit != 0) { a ^= 0x1B; }
      b >>= 1;
    }
    return p;
  }

  static const int _gfNine = 9, _b = 0xB, _d = 0xD, _e = 0xE;

  // AES Key Expansion (AES-128: 10 rounds)
  static List<Uint8List> _keyExpansion(Uint8List key) {
    final w = List<int>.filled(44 * 4, 0);
    for (int i = 0; i < 16; i++) { w[i] = key[i]; }

    for (int i = 4; i < 44; i++) {
      int temp = (w[(i - 1) * 4] << 24) |
          (w[(i - 1) * 4 + 1] << 16) |
          (w[(i - 1) * 4 + 2] << 8) |
          w[(i - 1) * 4 + 3];

      if (i % 4 == 0) {
        // RotWord
        temp = ((temp << 8) | (temp >> 24)) & 0xFFFFFFFF;
        // SubWord
        temp = (_sBox[(temp >> 24) & 0xFF] << 24) |
            (_sBox[(temp >> 16) & 0xFF] << 16) |
            (_sBox[(temp >> 8) & 0xFF] << 8) |
            _sBox[temp & 0xFF];
        // Rcon XOR
        temp ^= _rcon[(i ~/ 4) - 1] << 24;
      }

      final prev = (i - 4) * 4;
      final cur = i * 4;
      w[cur] = w[prev] ^ ((temp >> 24) & 0xFF);
      w[cur + 1] = w[prev + 1] ^ ((temp >> 16) & 0xFF);
      w[cur + 2] = w[prev + 2] ^ ((temp >> 8) & 0xFF);
      w[cur + 3] = w[prev + 3] ^ (temp & 0xFF);
    }

    return List.generate(11, (round) {
      final rk = Uint8List(16);
      for (int i = 0; i < 16; i++) { rk[i] = w[round * 16 + i]; }
      return rk;
    });
  }

  // ─── Yardımcı fonksiyonlar ───────────────────────────────────────────────────

  static Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }

  static String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static bool _isValidJson(String text) {
    final t = text.trim();
    return (t.startsWith('{') || t.startsWith('[')) && !t.contains('<html');
  }

  // ─── AES S-Box ve Rcon Tabloları ────────────────────────────────────────────

  static const List<int> _sBox = [
    0x63,0x7c,0x77,0x7b,0xf2,0x6b,0x6f,0xc5,0x30,0x01,0x67,0x2b,0xfe,0xd7,0xab,0x76,
    0xca,0x82,0xc9,0x7d,0xfa,0x59,0x47,0xf0,0xad,0xd4,0xa2,0xaf,0x9c,0xa4,0x72,0xc0,
    0xb7,0xfd,0x93,0x26,0x36,0x3f,0xf7,0xcc,0x34,0xa5,0xe5,0xf1,0x71,0xd8,0x31,0x15,
    0x04,0xc7,0x23,0xc3,0x18,0x96,0x05,0x9a,0x07,0x12,0x80,0xe2,0xeb,0x27,0xb2,0x75,
    0x09,0x83,0x2c,0x1a,0x1b,0x6e,0x5a,0xa0,0x52,0x3b,0xd6,0xb3,0x29,0xe3,0x2f,0x84,
    0x53,0xd1,0x00,0xed,0x20,0xfc,0xb1,0x5b,0x6a,0xcb,0xbe,0x39,0x4a,0x4c,0x58,0xcf,
    0xd0,0xef,0xaa,0xfb,0x43,0x4d,0x33,0x85,0x45,0xf9,0x02,0x7f,0x50,0x3c,0x9f,0xa8,
    0x51,0xa3,0x40,0x8f,0x92,0x9d,0x38,0xf5,0xbc,0xb6,0xda,0x21,0x10,0xff,0xf3,0xd2,
    0xcd,0x0c,0x13,0xec,0x5f,0x97,0x44,0x17,0xc4,0xa7,0x7e,0x3d,0x64,0x5d,0x19,0x73,
    0x60,0x81,0x4f,0xdc,0x22,0x2a,0x90,0x88,0x46,0xee,0xb8,0x14,0xde,0x5e,0x0b,0xdb,
    0xe0,0x32,0x3a,0x0a,0x49,0x06,0x24,0x5c,0xc2,0xd3,0xac,0x62,0x91,0x95,0xe4,0x79,
    0xe7,0xc8,0x37,0x6d,0x8d,0xd5,0x4e,0xa9,0x6c,0x56,0xf4,0xea,0x65,0x7a,0xae,0x08,
    0xba,0x78,0x25,0x2e,0x1c,0xa6,0xb4,0xc6,0xe8,0xdd,0x74,0x1f,0x4b,0xbd,0x8b,0x8a,
    0x70,0x3e,0xb5,0x66,0x48,0x03,0xf6,0x0e,0x61,0x35,0x57,0xb9,0x86,0xc1,0x1d,0x9e,
    0xe1,0xf8,0x98,0x11,0x69,0xd9,0x8e,0x94,0x9b,0x1e,0x87,0xe9,0xce,0x55,0x28,0xdf,
    0x8c,0xa1,0x89,0x0d,0xbf,0xe6,0x42,0x68,0x41,0x99,0x2d,0x0f,0xb0,0x54,0xbb,0x16,
  ];

  static const List<int> _invSBox = [
    0x52,0x09,0x6a,0xd5,0x30,0x36,0xa5,0x38,0xbf,0x40,0xa3,0x9e,0x81,0xf3,0xd7,0xfb,
    0x7c,0xe3,0x39,0x82,0x9b,0x2f,0xff,0x87,0x34,0x8e,0x43,0x44,0xc4,0xde,0xe9,0xcb,
    0x54,0x7b,0x94,0x32,0xa6,0xc2,0x23,0x3d,0xee,0x4c,0x95,0x0b,0x42,0xfa,0xc3,0x4e,
    0x08,0x2e,0xa1,0x66,0x28,0xd9,0x24,0xb2,0x76,0x5b,0xa2,0x49,0x6d,0x8b,0xd1,0x25,
    0x72,0xf8,0xf6,0x64,0x86,0x68,0x98,0x16,0xd4,0xa4,0x5c,0xcc,0x5d,0x65,0xb6,0x92,
    0x6c,0x70,0x48,0x50,0xfd,0xed,0xb9,0xda,0x5e,0x15,0x46,0x57,0xa7,0x8d,0x9d,0x84,
    0x90,0xd8,0xab,0x00,0x8c,0xbc,0xd3,0x0a,0xf7,0xe4,0x58,0x05,0xb8,0xb3,0x45,0x06,
    0xd0,0x2c,0x1e,0x8f,0xca,0x3f,0x0f,0x02,0xc1,0xaf,0xbd,0x03,0x01,0x13,0x8a,0x6b,
    0x3a,0x91,0x11,0x41,0x4f,0x67,0xdc,0xea,0x97,0xf2,0xcf,0xce,0xf0,0xb4,0xe6,0x73,
    0x96,0xac,0x74,0x22,0xe7,0xad,0x35,0x85,0xe2,0xf9,0x37,0xe8,0x1c,0x75,0xdf,0x6e,
    0x47,0xf1,0x1a,0x71,0x1d,0x29,0xc5,0x89,0x6f,0xb7,0x62,0x0e,0xaa,0x18,0xbe,0x1b,
    0xfc,0x56,0x3e,0x4b,0xc6,0xd2,0x79,0x20,0x9a,0xdb,0xc0,0xfe,0x78,0xcd,0x5a,0xf4,
    0x1f,0xdd,0xa8,0x33,0x88,0x07,0xc7,0x31,0xb1,0x12,0x10,0x59,0x27,0x80,0xec,0x5f,
    0x60,0x51,0x7f,0xa9,0x19,0xb5,0x4a,0x0d,0x2d,0xe5,0x7a,0x9f,0x93,0xc9,0x9c,0xef,
    0xa0,0xe0,0x3b,0x4d,0xae,0x2a,0xf5,0xb0,0xc8,0xeb,0xbb,0x3c,0x83,0x53,0x99,0x61,
    0x17,0x2b,0x04,0x7e,0xba,0x77,0xd6,0x26,0xe1,0x69,0x14,0x63,0x55,0x21,0x0c,0x7d,
  ];

  static const List<int> _rcon = [
    0x01,0x02,0x04,0x08,0x10,0x20,0x40,0x80,0x1b,0x36,
  ];
}

class _ChallengeSolution {
  final String cookie;
  final String? redirectUrl;
  _ChallengeSolution(this.cookie, this.redirectUrl);
}
