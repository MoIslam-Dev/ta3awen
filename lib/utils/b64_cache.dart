import 'dart:convert';
import 'dart:typed_data';

/// Small memory cache so base64 images are decoded at most once.
class B64Cache {
  static final Map<String, Uint8List> _cache = {};

  static Uint8List get(String b64) {
    final cached = _cache[b64];
    if (cached != null) return cached;
    if (_cache.length > 80) _cache.clear();
    final bytes = base64Decode(b64);
    _cache[b64] = bytes;
    return bytes;
  }
}
