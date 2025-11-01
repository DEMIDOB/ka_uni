import 'package:flutter/material.dart';
import 'package:kit_mobile/credentials/data/credentials_provider.dart';
import 'package:kit_mobile/credentials/views/login_view.dart';
import 'package:kit_mobile/ilias/files/ilias_file_manager.dart';
import 'package:kit_mobile/settings/providers/settings_provider.dart';
import 'package:kit_mobile/state_management/kit_provider.dart';
import 'package:kit_mobile/toasts/models/toasts_provider.dart';
import 'package:kit_mobile/toasts/views/toasts_overlay.dart';
import 'package:provider/provider.dart';

import 'constants.dart';
import 'navigation/views/kit_nav_container.dart';

const isAlpha = true;

void main() {
  // await initializeDateFormatting('de_DE', null);
  // Intl.defaultLocale = 'de_DE'; // Set the default locale

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    var themeData = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: mainColor,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: appleGrey,
      cardColor: Colors.white,
    );

    var textTheme = themeData.textTheme.copyWith(
      titleLarge: themeData.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      titleMedium: themeData.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      headlineSmall: themeData.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      headlineMedium: themeData.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
    );

    final bottomSheetThemeData = themeData.bottomSheetTheme.copyWith(
      backgroundColor: Color.fromRGBO(0, 0, 0, 0)
    );

    themeData = themeData.copyWith(
      textTheme: textTheme,
      bottomSheetTheme: bottomSheetThemeData
    );
    themeData = themeData.copyWith(
      appBarTheme: themeData.appBarTheme.copyWith(
        backgroundColor: appleGrey,
        surfaceTintColor: appleGrey,
        shadowColor: Colors.black38,
        // titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.normal)
      ),
    );

    var darkThemeData = ThemeData.dark();

    darkThemeData = darkThemeData.copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: mainColor, brightness: Brightness.dark), //, onBackground: Colors.red, background: Colors.red),
      textTheme: darkThemeData.textTheme.copyWith(
        titleLarge: darkThemeData.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        titleMedium: darkThemeData.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        headlineSmall: darkThemeData.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        headlineMedium: darkThemeData.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: darkThemeData.appBarTheme.copyWith(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.black,
      ),
      cardColor: appleDarkGrey,
      bottomSheetTheme: bottomSheetThemeData
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<KITProvider>(create: (ctx) => KITProvider()),
        ChangeNotifierProvider<CredentialsProvider>(create: (ctx) => CredentialsProvider(),),
        ChangeNotifierProvider<ToastsProvider>(create: (ctx) => ToastsProvider(),),
        ChangeNotifierProvider<SettingsProvider>(create: (ctx) => SettingsProvider(context: ctx),),
        ChangeNotifierProvider<IliasFileManager>(create: (ctx) => IliasFileManager(),)

      ],
      child: MaterialApp(
        title: "KA.Uni",
        theme: themeData,
        darkTheme: darkThemeData,
        builder: (context, child) {
          return Stack(
            children: [
              child ?? SizedBox(),
              ToastsOverlay()
            ],
          );
        },
        home: KITApp()
      )
    );
  }
}

class KITApp extends StatelessWidget {
  const KITApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Provider.of<KITProvider>(context).profileReady ? KITNavContainer() : LoginPage(),
    );
  }

}
