import 'package:flutter/material.dart';

/// A row of up to four buttons: delete, reset, cancel and save
class FormButtons extends StatelessWidget {
  const FormButtons({
    super.key,
    this.showDelete = false,
    this.onDelete,
    this.onReset,
    this.onCancel,
    this.onSave,
  });

  final bool showDelete;
  final Function()? onDelete;
  final Function()? onReset;
  final Function()? onCancel;
  final Function()? onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showDelete || onDelete != null) ...[
          ElevatedButton(
            onPressed: onDelete,
            style: ElevatedButton.styleFrom(
              // backgroundColor: Theme.of(context).colorScheme.error,
              // foregroundColor: Theme.of(context).colorScheme.onError,
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
            child: const Text('Delete'),
          ),
          const SizedBox(width: 20),
        ],
        if (onCancel != null) ...[
          ElevatedButton(
            onPressed: onCancel,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 20),
        ],
        if (onReset != null) ...[
          ElevatedButton(
            onPressed: onReset,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
            child: const Text('Reset'),
          ),
          const SizedBox(width: 20),
        ],
        ElevatedButton(
          onPressed: onSave,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
