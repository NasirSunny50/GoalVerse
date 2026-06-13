import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/compete_provider.dart';

/// Confirms before logging out (mirrors the "Exit GoalVerse?" flow), then logs
/// out — which drops the session and returns the Compete tab to the login
/// screen. [popAfter] closes the current pushed screen (e.g. Profile) so the
/// login is revealed underneath.
Future<void> confirmLogout(BuildContext context, {bool popAfter = false}) async {
  final nav = Navigator.of(context);
  final compete = context.read<CompeteProvider>();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Log out?'),
      content: const Text('You will be returned to the login screen.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: ctx.scheme.error,
            foregroundColor: Colors.white,
          ),
          child: const Text('Log out'),
        ),
      ],
    ),
  );
  if (ok != true) return;
  await compete.logout();
  if (popAfter) nav.pop();
}
