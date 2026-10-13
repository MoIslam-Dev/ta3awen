import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ta3awen/widgets/google_g_logo.dart';
import 'package:ta3awen/widgets/social_sign_in_button.dart';

void main() {
  group('GoogleGLogo', () {
    testWidgets('renders at the requested size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: GoogleGLogo(size: 40)),
        ),
      );
      expect(find.byType(GoogleGLogo), findsOneWidget);
      final size = tester.getSize(find.byType(GoogleGLogo));
      expect(size.width, 40);
      expect(size.height, 40);
    });
  });

  group('SocialSignInButton', () {
    testWidgets('shows the label and is tappable', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialSignInButton(
              label: 'المتابعة بواسطة Google',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );
      expect(find.text('المتابعة بواسطة Google'), findsOneWidget);
      expect(find.byType(GoogleGLogo), findsOneWidget);
      await tester.tap(find.byType(SocialSignInButton));
      expect(tapped, isTrue);
    });

    testWidgets('ignores taps while loading', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialSignInButton(
              label: 'Continue with Google',
              loading: true,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(SocialSignInButton), warnIfMissed: false);
      expect(tapped, isFalse);
    });
  });

  group('OrDivider', () {
    testWidgets('renders the separator label between lines', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: OrDivider(label: 'أو')),
        ),
      );
      expect(find.text('أو'), findsOneWidget);
      expect(find.byType(Divider), findsNWidgets(2));
    });
  });
}