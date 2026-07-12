import 'package:flutter/material.dart';

class CreateSessionResult {
  final String title;
  final String? summary;
  final String? location;

  const CreateSessionResult({
    required this.title,
    this.summary,
    this.location,
  });
}

class CreateSessionDialog extends StatefulWidget {
  const CreateSessionDialog({super.key});

  @override
  State<CreateSessionDialog> createState() =>
      _CreateSessionDialogState();
}

class _CreateSessionDialogState
    extends State<CreateSessionDialog> {
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      CreateSessionResult(
        title: title,
        summary: _emptyToNull(_summaryController.text),
        location: _emptyToNull(_locationController.text),
      ),
    );
  }

  String? _emptyToNull(String value) {
    final cleaned = value.trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Start Session'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Session title',
                hintText: 'Fuel-system work',
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _summaryController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Summary (optional)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location (optional)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Start Session'),
        ),
      ],
    );
  }
}