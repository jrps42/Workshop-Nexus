import 'package:flutter/material.dart';

import '../models/capture.dart';
import '../models/workspace.dart';

class CaptureList extends StatelessWidget {
  final List<Capture> captures;
  final List<Workspace> workspaces;
  final bool isLoading;

  final void Function(
    String captureId,
    String? workspaceId,
  ) onWorkspaceChanged;

  final ValueChanged<String> onDelete;

  const CaptureList({
    super.key,
    required this.captures,
    required this.workspaces,
    required this.isLoading,
    required this.onWorkspaceChanged,
    required this.onDelete,
  });

  String? _safeWorkspaceValue(String? workspaceId) {
    if (workspaceId == null) {
      return null;
    }

    final exists = workspaces.any(
      (workspace) => workspace.id == workspaceId,
    );

    return exists ? workspaceId : null;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (captures.isEmpty) {
      return const Center(
        child: Text('No captures here yet.'),
      );
    }

    return ListView.builder(
      itemCount: captures.length,
      itemBuilder: (context, index) {
        final capture = captures[index];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  capture.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(capture.content),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _safeWorkspaceValue(
                          capture.workspaceId,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Workspace',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Inbox'),
                          ),
                          ...workspaces.map(
                            (workspace) =>
                                DropdownMenuItem<String?>(
                              value: workspace.id,
                              child: Text(workspace.name),
                            ),
                          ),
                        ],
                        onChanged: (workspaceId) {
                          onWorkspaceChanged(
                            capture.id,
                            workspaceId,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete capture',
                      onPressed: () => onDelete(capture.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}