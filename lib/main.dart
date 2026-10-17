import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/navigator.dart';
import 'core/supabase.dart';
import 'l10n/gen/app_localizations.dart';
import 'screens/auth_gate.dart';
import 'services/push_service.dart';
import 'state/app_settings.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  // All date locales (ar/fr/en) so formatDate can follow the UI language.
  try {
    await initializeDateFormatting();
  } catch (_) {}
  await AppSettings.instance.load();
  runApp(const Ta3awenApp());
  // After the first frame: Firebase/FCM setup (it needs the activity for the
  // notification permission prompt) and device-token registration.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    PushService.instance.init();
  });
}

class Ta3awenApp extends StatelessWidget {
  const Ta3awenApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    return ValueListenableBuilder<Locale>(
      valueListenable: settings.locale,
      builder: (context, locale, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: settings.themeMode,
          builder: (context, themeMode, _) {
            return MaterialApp(
              title: 'Ta3awen',
              debugShowCheckedModeBanner: false,
              navigatorKey: appNavigatorKey,
              locale: locale,
              supportedLocales: const [
                Locale('ar'),
                Locale('fr'),
                Locale('en'),
              ],
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              home: const AuthGate(),
            );
          },
        );
      },
    );
  }
}
