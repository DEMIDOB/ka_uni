import 'package:flutter/material.dart';
import 'package:kit_mobile/common_ui/kit_progress_indicator.dart';
import 'package:kit_mobile/credentials/data/credentials_provider.dart';
import 'package:kit_mobile/local_files_storage/files_manager.dart';
import 'package:kit_mobile/settings/providers/settings_provider.dart';
import 'package:kit_mobile/state_management/kit_provider.dart';
import 'package:kit_mobile/toasts/models/toasts_provider.dart';
import 'package:kit_mobile/toasts/views/toasts_overlay.dart';
import 'package:kit_mobile/tutorials/data/tutorial_manager.dart';
import 'package:liquid_glass_widgets/liquid_glass_setup.dart';
import 'package:provider/provider.dart';

import 'constants/view_constants.dart';
import 'credentials/views/login_view.dart';
import 'navigation/views/kit_nav_container.dart';

const isAlpha = true;

void main() async {
  // await initializeDateFormatting('de_DE', null);
  // Intl.defaultLocale = 'de_DE'; // Set the default locale
  await LiquidGlassWidgets.initialize();

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
      canvasColor: Colors.white,
    );

    var textTheme = themeData.textTheme.copyWith(
      titleLarge:
          themeData.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      titleMedium: themeData.textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
      headlineSmall: themeData.textTheme.headlineSmall
          ?.copyWith(fontWeight: FontWeight.bold),
      headlineMedium: themeData.textTheme.headlineMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );

    final bottomSheetThemeData = themeData.bottomSheetTheme
        .copyWith(backgroundColor: Color.fromRGBO(0, 0, 0, 0));

    themeData = themeData.copyWith(
        textTheme: textTheme, bottomSheetTheme: bottomSheetThemeData);
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
        colorScheme: ColorScheme.fromSeed(
            seedColor: mainColor,
            brightness: Brightness
                .dark), //, onBackground: Colors.red, background: Colors.red),
        textTheme: darkThemeData.textTheme.copyWith(
          titleLarge: darkThemeData.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
          titleMedium: darkThemeData.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
          headlineSmall: darkThemeData.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
          headlineMedium: darkThemeData.textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: darkThemeData.appBarTheme.copyWith(
          backgroundColor: Colors.black,
          surfaceTintColor: Colors.black,
        ),
        cardColor: appleDarkGrey,
        bottomSheetTheme: bottomSheetThemeData,
        canvasColor: Colors.white,
    );

    return MultiProvider(
        providers: [
          ChangeNotifierProvider<KITProvider>(create: (ctx) => KITProvider()),
          ChangeNotifierProvider<CredentialsProvider>(
            create: (ctx) => CredentialsProvider(),
          ),
          ChangeNotifierProvider<ToastsProvider>(
            create: (ctx) => ToastsProvider(),
          ),
          ChangeNotifierProvider<SettingsProvider>(
            create: (ctx) => SettingsProvider(context: ctx),
          ),
          ChangeNotifierProvider<IliasFilesProvider>(
            create: (ctx) => IliasFilesProvider(),
          ),
          ChangeNotifierProvider<TutorialManager>(
            create: (ctx) => TutorialManager(),
          ),
        ],
        child: MaterialApp(
            title: "KA.Uni",
            theme: themeData,
            darkTheme: darkThemeData,
            builder: (context, child) {
              return Stack(
                children: [child ?? SizedBox(), ToastsOverlay(extraPadding: EdgeInsets.only(bottom: 40),)],
              );
            },
            home: KITApp()));
  }
}

class KITApp extends StatefulWidget {
  const KITApp({super.key});

  @override
  State<KITApp> createState() => _KITAppState();
}

class _KITAppState extends State<KITApp> {
  late Future<bool> _credentialsFuture;

  @override
  void initState() {
    super.initState();

    final vm = Provider.of<KITProvider>(context, listen: false);
    final credsVM = Provider.of<CredentialsProvider>(context, listen: false);
    final toastsProvider = Provider.of<ToastsProvider>(context, listen: false);

    _credentialsFuture = credsVM.loadCredentials(notify: false);
    _credentialsFuture.whenComplete(() async {
      if (credsVM.credentials.valid) {
        final preloadResult = await vm.tryPreloadCache(credsVM.credentials);

        if (!preloadResult) {
          // should never happen but just in case
          toastsProvider.showTextToast("Ungültige Zugangsdaten!");
          return;
        }

        await credsVM.login(vm);
        await vm.campusManager.fetchTimetable();
        await vm.campusManager.fetchAllModules(onlyMostImportantOnes: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<KITProvider>(context);

    return FutureBuilder(
        future: _credentialsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: KITProgressIndicator());
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: vm.profileReady ? KITNavContainer() : LoginPage(),
          );
        });
  }
}
