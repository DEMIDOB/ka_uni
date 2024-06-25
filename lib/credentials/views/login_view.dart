import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:kit_mobile/credentials/data/credentials_provider.dart';
import 'package:kit_mobile/credentials/models/auth_result.dart';
import 'package:kit_mobile/home/views/home_page.dart';
import 'package:kit_mobile/state_management/KITProvider.dart';
import 'package:kit_mobile/common_ui/kit_logo.dart';
import 'package:provider/provider.dart';

import '../../../common_ui/kit_progress_indicator.dart';

class LoginPage extends StatefulWidget {
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

    if (credsVM.credentialsLoaded) {
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
            appBar: AppBar(
              centerTitle: true,
              title: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  KITLogo(width: 50,),
                  Text(" Account")
                ],
              ),
            ),
            body: (!credsVM.credentialsLoaded || credsVM.loggingIn) ? const Center(child: KITProgressIndicator(),) : Container(
              padding: EdgeInsets.only(top: 20, bottom: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Text("Was ist das?"),
                  Column(
                    children: [
                      Text("Hallo", style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
                      Text("Wilkommen in Karlsruhe", style: theme.textTheme.headlineSmall?.copyWith(color: theme.primaryColor),),
                      // Text("Wilkommen im KIT", style: theme.textTheme.headlineSmall?.copyWith(color: theme.primaryColor),),
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        child: CupertinoTextField(
                          controller: _usernameInputController,
                          placeholder: "Username (uxxxx)",
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        child: CupertinoTextField(
                          controller: _passwordInputController,
                          placeholder: "Passwort",
                          obscureText: true,
                        ),
                      ),
                      CupertinoButton(child: Text("Einloggen"), onPressed: () => _submitLogin(credsVM, vm))
                    ],
                  )
                ],
              ),
            ),
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

  _submitLogin(CredentialsProvider credsVM, KITProvider vm) {
    credsVM.submit(_usernameInputController.text, _passwordInputController.text, vm).then((result) {
      if (result != AuthResult.ok) {
        if (kDebugMode) {
          print("Authentication failed: ${result}");
        }
        return;
      }

      if (kDebugMode) {
        print("Successfully authenticated");
      }

      _onSuccessfulLogin(credsVM, vm);
    });
  }

  _onSuccessfulLogin(CredentialsProvider credsVM, KITProvider vm) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return KITHomePage();
    }));
  }

}