import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kit_mobile/credentials/data/credentials_provider.dart';
import 'package:kit_mobile/credentials/views/login_view.dart';
import 'package:kit_mobile/state_management/KITProvider.dart';
import 'package:provider/provider.dart';

import 'home/views/home_page.dart';

const isAlpha = true;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final mainColor = Color.fromARGB(1, 0, 150, 130);

    var themeData = ThemeData(
      colorScheme: ColorScheme.fromSeed(
          seedColor: mainColor
      ),
      useMaterial3: true,
    );

    var textTheme = themeData.textTheme.copyWith(
      titleLarge: themeData.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      titleMedium: themeData.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      headlineSmall: themeData.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      headlineMedium: themeData.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
    );

    var darkThemeData = ThemeData.dark();

    darkThemeData = darkThemeData.copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: mainColor, brightness: Brightness.dark, onBackground: Colors.red, background: Colors.red),
      textTheme: darkThemeData.textTheme.copyWith(
        titleLarge: darkThemeData.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        titleMedium: darkThemeData.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        headlineSmall: darkThemeData.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        headlineMedium: darkThemeData.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: darkThemeData.appBarTheme
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<KITProvider>(create: (ctx) => KITProvider()),
        ChangeNotifierProvider<CredentialsProvider>(create: (ctx) => CredentialsProvider(),)
      ],
      child: MaterialApp(
        title: 'KIT mobile',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: Color.fromARGB(1, 0, 150, 130)
          ),
          textTheme: textTheme,
          useMaterial3: true,
        ),
        darkTheme: darkThemeData,
        home: KITApp()
      )
    );
  }
}

class KITApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Provider.of<KITProvider>(context).profileReady ? KITHomePage() : LoginPage(),
    );
  }

}