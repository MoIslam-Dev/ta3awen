/// Full-text search helpers.
///
/// Firestore cannot do substring/LIKE searches, so every listing stores a
/// `keywords` array holding each word of its text plus every prefix of each
/// word (min length 1, capped at [kMaxSearchTokenLength]). The feed queries
/// with `arrayContainsAny` on the raw query words and then AND-filters on the
/// client with [keywordsMatch].
///
/// Normalization is applied identically to indexed text and queries:
/// lowercase, tashkeel stripped, alef/hamza/teh-marbuta unified — so
/// 'أَلْبِاب' and 'الباب' both become 'الباب'.
const int kMaxSearchTokenLength = 16;
const int kMaxQueryTokens = 30;

final RegExp _diacritics = RegExp(r'[\u064B-\u0652\u0640\u0670\u06D6-\u06ED]');
final RegExp _nonToken = RegExp(r'[^0-9a-z\u0621-\u064A]+');
final RegExp _alef = RegExp('[أإآٱ]');

String normalizeSearchText(String input) {
  var s = input.toLowerCase().replaceAll(_diacritics, '');
  s = s.replaceAll(_alef, 'ا');
  s = s.replaceAll('ى', 'ي');
  s = s.replaceAll('ؤ', 'و');
  s = s.replaceAll('ئ', 'ي');
  s = s.replaceAll('ة', 'ه');
  return s;
}

/// Normalized, deduplicated, length-capped tokens of [text].
List<String> searchTokens(String text) {
  final out = <String>{};
  for (final part in normalizeSearchText(text).split(_nonToken)) {
    if (part.isEmpty) continue;
    out.add(part.length > kMaxSearchTokenLength
        ? part.substring(0, kMaxSearchTokenLength)
        : part);
  }
  return out.toList();
}

/// The `keywords` array for a listing: every token of [title], [description]
/// and the facet fields, plus every prefix of every token (so partial words
/// typed while searching still match).
List<String> buildKeywords({
  required String title,
  required String description,
  String category = '',
  String wilaya = '',
  String commune = '',
  String condition = '',
}) {
  final out = <String>{};
  final texts = [title, description, category, wilaya, commune, condition];
  for (final text in texts) {
    for (final token in searchTokens(text)) {
      for (var i = 1; i <= token.length; i++) {
        out.add(token.substring(0, i));
      }
    }
  }
  return out.toList();
}

/// True when every query word of [query] appears in [keywords] (AND
/// semantics over the server-side `arrayContainsAny` superset).
/// An empty/blank query matches everything.
bool keywordsMatch(Iterable<String> keywords, String query) {
  final tokens = searchTokens(query);
  if (tokens.isEmpty) return true;
  return tokens.every(keywords.contains);
}
