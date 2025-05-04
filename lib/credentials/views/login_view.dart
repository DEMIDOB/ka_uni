import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:kit_mobile/common_ui/alpha_badge.dart';
import 'package:kit_mobile/credentials/data/credentials_provider.dart';
import 'package:kit_mobile/credentials/models/auth_result.dart';
import 'package:kit_mobile/state_management/KITProvider.dart';
import 'package:provider/provider.dart';

import '../../../common_ui/kit_progress_indicator.dart';
import '../../info/views/info_view.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return LoginPageState();
  }

}

class LoginPageState extends State<LoginPage> {
  final _usernameInputController = TextEditingController();
  final _passwordInputController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final credsVM = Provider.of<CredentialsProvider>(context);
    final vm = Provider.of<KITProvider>(context);

    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);

    final myCupertinoInputDecoration = BoxDecoration(
      color: CupertinoDynamicColor.withBrightness(
        color: CupertinoColors.white,
        darkColor: CupertinoColors.darkBackgroundGray,
      ),
      border: Border.all(color: Colors.grey.withOpacity(0.2)),
      borderRadius: BorderRadius.all(Radius.circular(5.0))
    );

    if (credsVM.credentialsLoaded && _usernameInputController.text.isEmpty) {
      _usernameInputController.text = credsVM.credentials.username;
      _passwordInputController.text = credsVM.credentials.password;

      if (credsVM.credentials.valid && !vm.profileReady && !credsVM.loggingIn) {
        Timer(const Duration(milliseconds: 50), () {
          _submitLogin(credsVM, vm);

        });
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          Scaffold(
            // appBar: AppBar(
            //   backgroundColor: Colors.white.withOpacity(0),
            //   centerTitle: true,
            //   title: const Row(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     crossAxisAlignment: CrossAxisAlignment.center,
            //     children: [
            //       // KITLogo(width: 100,),
            //       Text(" Account")
            //     ],
            //   ),
            // ),
            body: Stack(
              children: [
              AnimatedOpacity(
              opacity: !credsVM.loggingIn ? 1 : 0,
                duration: Duration(milliseconds: 250),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text("Hallo", style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
                        Text("Wilkommen in Karlsruhe", style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary),),
                        // Text("Wilkommen im KIT", style: theme.textTheme.headlineSmall?.copyWith(color: theme.primaryColor),),
                      ],
                    ),
                    // (!credsVM.credentialsLoaded || credsVM.loggingIn) ? const KITProgressIndicator() :
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          child: CupertinoTextField(
                            controller: _usernameInputController,
                            placeholder: "Username (uxxxx)",
                            enabled: (credsVM.credentialsLoaded && !credsVM.loggingIn),
                            autocorrect: false,
                            style: theme.textTheme.bodyMedium,
                            decoration: myCupertinoInputDecoration,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          child: CupertinoTextField(
                            controller: _passwordInputController,
                            // onChanged: (val) => _passwordInputController.text,
                            placeholder: "Passwort",
                            enabled: (credsVM.credentialsLoaded && !credsVM.loggingIn),
                            keyboardType: TextInputType.visiblePassword,
                            obscureText: true,
                            style: theme.textTheme.bodyMedium,
                            decoration: myCupertinoInputDecoration,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CupertinoButton(child: Text("Was ist das?"), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => InfoView()))),
                            CupertinoButton(child: Text("Einloggen"), onPressed: () => _submitLogin(credsVM, vm))
                          ],
                        )
                      ],
                    )
                  ],
                )
              ),

                AnimatedPositioned(
                  top: _awaitingAuthentication ? -mq.size.height * 0.5 : mq.size.height * 0.3,
                    curve: Curves.ease,
                    duration: const Duration(milliseconds: 750),
                  child: AnimatedOpacity(
                      curve: Curves.ease,
                      duration: const Duration(milliseconds: 750),
                    opacity: _awaitingAuthentication ? 1 : 0.5,
                    child: Container(
                        decoration: BoxDecoration(
                            boxShadow: [BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(theme.brightness == Brightness.light ? 0.8 : 0.5),
                              blurRadius: 50,
                              spreadRadius: 20,
                            )],
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.all(Radius.circular(mq.size.width * 7))
                        ),
                        width: mq.size.width * 7,
                        height: mq.size.width * 7
                    ),
                  )

                ),

                AnimatedOpacity(
                  opacity: _awaitingAuthentication ? 1 : 0,
                  duration: Duration(milliseconds: 250),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: mq.size.width * 0.3,
                          child: const AlphaBadge(),
                        ),

                        Column(
                          children: [
                            SizedBox(
                              width: mq.size.width,
                              // height: 125,
                              child: Center(
                                child: Hero(
                                  tag: "greeting",
                                  child: Text("Hallo, ${credsVM.displayName}", style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white), maxLines: 2,),
                                ),
                              ),
                            ),

                            SizedBox(height: 25,),

                            KITProgressIndicator(color: Colors.white,),
                          ],
                        ),

                        SizedBox(width: mq.size.width, height: 0,)
                      ],
                    ),
                  ),
                )
              ],
            )
          ),

          vm.overlayHtmlData.isNotEmpty ? BackdropFilter(
            // color: Colors.black12,
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: ListView(
              children: [
                CupertinoButton(onPressed: vm.dismissOverlayHtml, child: const Text("Dismiss")),
                HtmlWidget(vm.overlayHtmlData)
              ],
            ),
          ) : const Text("")
        ],
      )
    );
  }

  bool _awaitingAuthentication = false;

  _submitLogin(CredentialsProvider credsVM, KITProvider vm) {
    if (kDebugMode) {
      print("Submitted Login");
    }
    if (_awaitingAuthentication) {
      return;
    }

    setState(() {
      _awaitingAuthentication = true;
    });

    credsVM.submit(_usernameInputController.text, _passwordInputController.text, vm).then((result) {
      if (result != AuthResult.ok) {
        if (kDebugMode) {
          print("Authentication failed: $result");
        }
        setState(() {
          _awaitingAuthentication = false;
        });
        return;
      }

      if (kDebugMode) {
        print("Successfully authenticated");
      }

      setState(() {
        _awaitingAuthentication = false;
      });
      _onSuccessfulLogin(credsVM, vm);
    });
  }

  _onSuccessfulLogin(CredentialsProvider credsVM, KITProvider vm) {
    credsVM.setDisplayName(vm.student.name.repr);
  }

}