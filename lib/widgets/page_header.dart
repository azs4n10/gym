import 'package:flutter/material.dart';

import '../state/app_state.dart';

/// Page title row used instead of an AppBar on tab pages.
class PageHeader extends StatelessWidget {
  const PageHeader(this.title, {super.key, this.actions = const []});

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: skin.heading,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
