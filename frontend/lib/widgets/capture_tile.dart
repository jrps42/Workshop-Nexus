import 'package:flutter/material.dart';

import '../models/capture.dart';
import '../models/workspace.dart';

class CaptureTile extends StatelessWidget {
  final Capture capture;
  final List<Workspace> workspaces;

  final VoidCallback onTap;
  final ValueChanged<String?> onWorkspaceChanged;
  final VoidCallback onDelete;

  const CaptureTile({
    super.key,
    required this.capture,
    required this.workspaces,
    required this.onTap,
    required this.onWorkspaceChanged,
    required this.onDelete,
  });

  String? _safeWorkspaceValue() {
    final workspaceId = capture.workspaceId;

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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      capture.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.open_in_new,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                capture.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: _safeWorkspaceValue(),
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
                      onChanged: onWorkspaceChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Delete capture',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}