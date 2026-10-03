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
}
