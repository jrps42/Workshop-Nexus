import 'package:flutter/material.dart';

class CaptureEditor extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSaving;

  final String? statusMessage;
  final String? errorMessage;

  final KeyEventResult Function(FocusNode, KeyEvent) onKeyEvent;

  final VoidCallback onSave;
  final VoidCallback onSaveToInbox;
  final VoidCallback onClear;
  final VoidCallback onRefresh;

  const CaptureEditor({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isSaving,
    required this.statusMessage,
    required this.errorMessage,
    required this.onKeyEvent,
    required this.onSave,
    required this.onSaveToInbox,
    required this.onClear,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'What would you like to remember?',
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 12),
        Focus(
          focusNode: focusNode,
          onKeyEvent: onKeyEvent,
          child: TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText:
                  'Type a thought, idea, task, note, or project detail...',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton(
              onPressed: isSaving ? null : onSave,
              child: Text(
                isSaving ? 'Saving...' : 'Save Capture',
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: isSaving ? null : onSaveToInbox,
              child: const Text('Save to Inbox'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onClear,
              child: const Text('Clear'),
            ),
            const Spacer(),
            IconButton(
              onPressed: onRefresh,
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Ctrl+Enter: save with context · '
          'Ctrl+Shift+Enter: save to Inbox',
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 12),
        if (statusMessage != null)
          Text(
            statusMessage!,
            style: const TextStyle(color: Colors.green),
          ),
        if (errorMessage != null)
          Text(
            errorMessage!,
            style: const TextStyle(color: Colors.red),
          ),
      ],
    );
  }
}