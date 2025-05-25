import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:kit_mobile/common_ui/kit_logo.dart';
import 'package:kit_mobile/state_management/kit_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common_ui/block_container.dart';

class InfoView extends StatefulWidget {
  const InfoView({super.key});

  @override
  State<StatefulWidget> createState() {
    return _InfoViewState();
  }
}

class _InfoViewState extends State<InfoView> {
  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<KITProvider>(context);
    final mq = MediaQuery.of(context);
    final theme = Theme.of(context);

    bool isPersonalized = vm.profileReady;

    final greeting = isPersonalized ? "Hi, ${vm.student.name.repr}!" : "Hallo";

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Text("Was ist"),
            KITLogo()
          ],
        ),
        actions: [
          CupertinoButton(
            child: SizedBox(
              width: 20,
              height: 20,
              child: SvgPicture.asset(
                "assets/images/GitHub.svg",
                colorFilter: ColorFilter.mode(
                    theme.colorScheme.primary, BlendMode.srcIn),
              ),
            ),
            onPressed: () =>
                launchUrl(Uri.parse("https://github.com/DEMIDOB/ka_uni")),
          )
        ],
        centerTitle: true,
      ),
      body: ListView(
        children: [
          Container(
            width: mq.size.width,
            padding: const EdgeInsets.only(top: 10.0, left: 25, right: 25),
            child: Hero(
              tag: "greeting",
              child: Text(
                greeting,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: mq.size.width - 30,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                        child: Text(
                          "Wir sind sehr froh, dass du sich für diese "
                          "App interessiert! Von Studenten für Studenten: Diese App dient dazu, dein Studentenleben "
                          "am KIT freundlicher und einfacher zu machen. ",
                          maxLines: 10,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),

                CupertinoButton(
                    child: Text("Privacy Policy"),
                    onPressed: () {
                      FlutterWebBrowser.openWebPage(
                          url: "https://dandemidov.com/ka_uni/privacy_policy/");
                    }),

                InfoViewFaqSection(
                    title:
                        "Wie kann ich mir sicher sein, dass meine Daten nicht gestolen werden?",
                    body:
                        "Alles wird nur auf deinem Gerät verarbeitet, als würdest"
                        " du das Campus-Portal in deinem Web-Browser benutzen. "
                        "Die App ist auch open-source. Das heißt, du kannst sich den Code anschauen, "
                        "um sicherzustellen, dass alles in Ordnung ist. "
                        "Du kannst auch das Repo klonen und deine eigene Version benutzen."),

                // !isAlpha ? Text("") : Container(
                //   padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                //   decoration: BoxDecoration(
                //     borderRadius: BorderRadius.all(Radius.circular(5)),
                //     border: Border.all(color: Colors.red)
                //   ),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //     children: [
                //       Text("α", style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red, fontWeight: FontWeight.bold)),
                //       Text("Die App ist noch in alpha!", style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red, fontWeight: FontWeight.bold),),
                //       Text("α", style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red, fontWeight: FontWeight.bold)),
                //     ],
                //   ),
                // ),

                const InfoViewFaqSection(
                    title: "Kann ich zur Entwicklung beitragen?",
                    body:
                        "Ja! Wir würden uns darüber sehr freuen! Wenn du sich mit Flutter auskennst und beitragen möchtest, kontaktiere uns per Telegram: @XtremeUserInterfaces."),

                const InfoViewFaqSection(
                    title: "Wie geht es weiter?",
                    body:
                        "Viele Features sind geplannt, wie z.B. ILIAS, Benachrichtigungen über Änderungen und noch mehr! "
                        "Daran arbeiten wir jetzt. Wenn du Ideen hast, welche Features es noch in der App "
                        "geben soll und/oder wie wir die App noch verbessern könnten, dann schreibe uns gerne!"),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class InfoViewFaqSection extends StatelessWidget {
  final String title, body;

  const InfoViewFaqSection(
      {super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);

    return BlockContainer(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(
            width: mq.size.width - 20,
            child: Text(
              body,
              maxLines: 10,
            ),
          )
        ],
      ),
    );
  }
}
