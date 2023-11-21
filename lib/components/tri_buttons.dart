import 'package:flutter/material.dart';

/// A row of three buttons: delete, reset, and save
class TriButtons extends StatelessWidget {
  const TriButtons({
    super.key,
    required this.allowDelete,
    this.onDelete,
    this.onReset,
    this.onSave,
  });

  final bool allowDelete;
  final Function()? onDelete;
  final Function()? onReset;
  final Function()? onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (allowDelete) ...[
          ElevatedButton(
            onPressed: onDelete,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
          const SizedBox(width: 20),
        ],
        ElevatedButton(
          onPressed: onReset,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
          ),
          child: const Text('Reset'),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: onSave,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
