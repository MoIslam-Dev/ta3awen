/// Full-text search helpers.
///
/// Search runs in Postgres against a normalized `search_text` column (trigram
/// `ILIKE`, see `supabase/migrations/0006`). The client only needs
/// [normalizeSearchText]/[searchTokens] to normalize the query exactly like the
/// database's `normalize_ar()` does, so 'أَلْبِاب' and 'الباب' both search as
/// 'الباب'.
///
/// [buildKeywords]/[keywordsMatch] are the legacy prefix-index helpers, kept
/// for their unit tests.
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
