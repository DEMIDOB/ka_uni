import 'package:flutter/material.dart';

class PaddedTitle extends StatelessWidget {
  final String title;

  const PaddedTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
        children: [
          const Padding(padding: EdgeInsets.all(4)),
          Text(title, style: theme.textTheme.titleLarge),
          const Padding(padding: EdgeInsets.all(5)),
        ],
      );

  }

}