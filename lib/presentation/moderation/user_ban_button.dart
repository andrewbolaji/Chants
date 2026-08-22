import 'package:flutter/material.dart';

class UserBanButton extends StatelessWidget {
  final bool banned;
  final VoidCallback onBan;
  final VoidCallback onUnban;

  const UserBanButton({
    super.key,
    required this.banned,
    required this.onBan,
    required this.onUnban,
  });

  @override
  Widget build(BuildContext context) {
    if (banned) {
      return OutlinedButton(onPressed: onUnban, child: const Text('Unban'));
    }

    return FilledButton.tonal(
      onPressed: onBan,
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
      ),
      child: const Text('Ban'),
    );
  }
}
