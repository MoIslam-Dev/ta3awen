import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ta3awen/l10n/gen/app_localizations.dart';
import 'package:ta3awen/utils/errors.dart';

Future<String> _map(WidgetTester tester, Object error) async {
  String? label;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          label = authErrorMessage(context, error);
          return const SizedBox();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return label!;
}

Future<void> _expect(WidgetTester tester, Object error, String expected) async {
  expect(await _map(tester, error), expected);
}

void main() {
  group('authErrorMessage - social sign-in', () {
    testWidgets('user closes the Google sheet -> cancelled', (tester) async {
      await _expect(
        tester,
        Exception('google-sign-in aborted-by-user'),
        'تم إلغاء تسجيل الدخول',
      );
    });

    testWidgets('platform cancellation exception -> cancelled', (tester) async {
      await _expect(
        tester,
        'GoogleSignInException(code canceled, x, null)',
        'تم إلغاء تسجيل الدخول',
      );
    });

    testWidgets('interrupted Google flow -> cancelled', (tester) async {
      await _expect(
        tester,
        'GoogleSignInException(code interrupted, x, null)',
        'تم إلغاء تسجيل الدخول',
      );
    });

    testWidgets('misconfigured client -> config help', (tester) async {
      await _expect(
        tester,
        Exception('google-sign-in provider-config'),
        'تعذّر الاتصال بخدمة Google، تحقّق من الإعدادات وحاول مجدداً',
      );
    });

    testWidgets('SHA-1 mismatch (Android 10 INVALID_CLIENT_APPLICATION) -> config help',
        (tester) async {
      await _expect(
        tester,
        'PlatformException(sign_in_failed, 10: INVALID_CLIENT_APPLICATION, '
            'Your application ID 1:123:android:abc is not allowed, null)',
        'تعذّر الاتصال بخدمة Google، تحقّق من الإعدادات وحاول مجدداً',
      );
    });

    testWidgets('Google provider disabled in console -> disabled help', (tester) async {
      await _expect(
        tester,
        'FirebaseAuthException: [firebase_auth/operation-not-allowed]',
        'هذا الخيار غير مفعّل حالياً، جرّب البريد الإلكتروني',
      );
    });
  });

  group('authErrorMessage - classic email/password errors still map', () {
    testWidgets('wrong credentials', (tester) async {
      await _expect(
        tester,
        'FirebaseAuthException: [firebase_auth/invalid-credential]',
        'البريد الإلكتروني أو كلمة المرور غير صحيحة',
      );
    });

    testWidgets('network unreachable', (tester) async {
      await _expect(
        tester,
        'FirebaseAuthException: [firebase_auth/network-request-failed]',
        'تعذّر الاتصال بالإنترنت، تحقق من شبكتك',
      );
    });

    testWidgets('email already in use', (tester) async {
      await _expect(
        tester,
        'FirebaseAuthException: [firebase_auth/email-already-in-use]',
        'هذا البريد الإلكتروني مسجّل مسبقاً',
      );
    });
  });
}