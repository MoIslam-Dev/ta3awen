import 'package:flutter_test/flutter_test.dart';
import 'package:ta3awen/utils/search_keywords.dart';

void main() {
  group('normalizeSearchText', () {
    test('strips tashkeel and unifies alef forms', () {
      expect(normalizeSearchText('أَلْبِاب'), 'الباب');
      expect(normalizeSearchText('إسم'), 'اسم');
      expect(normalizeSearchText('آمل'), 'امل');
    });

    test('unifies teh marbuta, alef maqsura and hamza carriers', () {
      expect(normalizeSearchText('رياضة'), 'رياضه');
      expect(normalizeSearchText('مصطفى'), 'مصطفي');
      expect(normalizeSearchText('مؤمن'), 'مومن');
      expect(normalizeSearchText('مسئول'), 'مسيول');
    });

    test('lowercases latin text', () {
      expect(normalizeSearchText('Samsung A52'), 'samsung a52');
    });
  });

  group('searchTokens', () {
    test('splits on punctuation and keeps arabic/latin words', () {
      expect(searchTokens('دراجة هوائية، للبيع!'),
          ['دراجه', 'هواييه', 'للبيع']);
    });

    test('removes diacritics before splitting so words stay whole', () {
      expect(searchTokens('مُحَمَّد'), ['محمد']);
    });

    test('caps token length at 16 chars', () {
      final tokens = searchTokens('ا' * 40);
      expect(tokens.single.length, kMaxSearchTokenLength);
    });

    test('deduplicates repeated words', () {
      expect(searchTokens('كرسي كرسي'), ['كرسي']);
    });
  });

  group('buildKeywords', () {
    test('contains every prefix of title tokens', () {
      final keywords = buildKeywords(title: 'دراجة', description: '');
      expect(keywords, containsAll(['د', 'در', 'درا', 'دراج', 'دراجه']));
    });

    test('includes description and facet fields', () {
      final keywords = buildKeywords(
        title: 'كرسي خشبي',
        description: 'للبيع في وهران',
        category: 'أثاث',
        wilaya: 'وهران',
        commune: 'بئر الجير',
        condition: 'مستعمل',
      );
      expect(keywords, contains('خشبي'));
      expect(keywords, contains('للبيع'));
      expect(keywords, contains('اث'));
      expect(keywords, contains('وهران'));
      expect(keywords, contains('بير'));
      expect(keywords, contains('مستعمل'));
    });

    test('latin words are lowercased and indexed', () {
      final keywords =
          buildKeywords(title: 'هاتف Samsung', description: '');
      expect(keywords, contains('samsung'));
      expect(keywords, contains('sam'));
    });
  });

  group('keywordsMatch', () {
    final keywords = buildKeywords(
      title: 'دراجة هوائية للبيع',
      description: 'حالة جيدة جدا',
      wilaya: 'وهران',
    );

    test('matches full and partial words', () {
      expect(keywordsMatch(keywords, 'دراجة'), true);
      expect(keywordsMatch(keywords, 'دراج'), true);
      expect(keywordsMatch(keywords, 'د'), true);
      expect(keywordsMatch(keywords, 'هو'), true);
    });

    test('multi-word queries require ALL words (AND)', () {
      expect(keywordsMatch(keywords, 'دراجة هوائية'), true);
      expect(keywordsMatch(keywords, 'دراجة كرسي'), false);
      expect(keywordsMatch(keywords, 'وهران هوائية'), true);
    });

    test('blank query matches everything', () {
      expect(keywordsMatch(keywords, ''), true);
      expect(keywordsMatch(keywords, '   '), true);
    });

    test('query is normalized before matching', () {
      expect(keywordsMatch(keywords, 'دَراجَة'), true);
      expect(keywordsMatch(keywords, 'كرسي'), false);
    });
  });

  group('rules caps (must stay under firestore.rules limits)', () {
    test('adversarial max-length texts stay within 3000 keywords', () {
      const alphabet = 'abcdefghijklmnopqrstuvwxy';
      String dense(int n) {
        final buf = StringBuffer();
        for (var i = 0; buf.length < n; i++) {
          buf.write(alphabet[i % alphabet.length]);
          if (i % 5 == 4) buf.write(' ');
        }
        return buf.toString().substring(0, n);
      }

      final keywords = buildKeywords(
        title: dense(80),
        description: dense(800),
        category: 'aaaaaaaaaaaaaaaa',
        wilaya: 'bbbbbbbbbbbbbbbb',
        commune: 'cccccccccccccccc',
        condition: 'dddddddddddddddd',
      );
      expect(keywords.length, lessThanOrEqualTo(3000));
      expect(keywords.every((k) => k.length <= 16), true);
      expect(keywords, isNotEmpty);
    });

    test('max-length single tokens produce at most 16 prefixes each', () {
      final keywords = buildKeywords(
        title: 'z' * 80,
        description: 'y' * 800,
      );
      expect(keywords.every((k) => k.length <= 16), true);
      expect(keywords.length, lessThanOrEqualTo(3000));
    });
  });
}
