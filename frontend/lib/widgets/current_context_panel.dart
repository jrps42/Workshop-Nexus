import 'package:flutter/material.dart';

import '../models/session.dart';
import '../models/workspace.dart';

class CurrentContextPanel extends StatelessWidget {
  final List<Workspace> workspaces;
  final List<NexusSession> availableSessions;

  final bool isLoadingSessions;

  final String? activeWorkspaceId;
  final String? activeSessionId;

  final ValueChanged<String?> onWorkspaceChanged;
  final ValueChanged<String?> onSessionChanged;

  final VoidCallback onLeaveContext;
  final VoidCallback onStartSession;
  final VoidCallback onCompleteSession;
  final VoidCallback onShowSessionHistory;

  const CurrentContextPanel({
    super.key,
    required this.workspaces,
    required this.availableSessions,
    required this.isLoadingSessions,
    required this.activeWorkspaceId,
    required this.activeSessionId,
    required this.onWorkspaceChanged,
    required this.onSessionChanged,
    required this.onLeaveContext,
    required this.onStartSession,
    required this.onCompleteSession,
    required this.onShowSessionHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.adjust),
                const SizedBox(width: 8),
                const Text(
                  'Current Context',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed:
                      activeWorkspaceId == null && activeSessionId == null
                          ? null
                          : onLeaveContext,
                  icon: const Icon(Icons.clear),
                  label: const Text('Leave Context'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: activeWorkspaceId,
                    decoration: const InputDecoration(
                      labelText: 'Active Workspace',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No workspace — Inbox'),
                      ),
                      ...workspaces.map(
                        (workspace) => DropdownMenuItem<String?>(
                          value: workspace.id,
                          child: Text(workspace.name),
                        ),
                      ),
                    ],
                    onChanged: onWorkspaceChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: activeSessionId,
                    decoration: const InputDecoration(
                      labelText: 'Active Session',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No session'),
                      ),
                      ...availableSessions.map(
                        (session) => DropdownMenuItem<String?>(
                          value: session.id,
                          child: Text(session.title),
                        ),
                      ),
                    ],
                    onChanged:
                        isLoadingSessions ? null : onSessionChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: onStartSession,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start New Session'),
                ),
                OutlinedButton.icon(
                  onPressed:
                      activeSessionId == null ? null : onCompleteSession,
                  icon: const Icon(Icons.stop),
                  label: const Text('Complete Active Session'),
                ),
                OutlinedButton.icon(
                  onPressed: onShowSessionHistory,
                  icon: const Icon(Icons.history),
                  label: const Text('Session History'),
                ),
                Text(
                  activeSessionId == null
                      ? 'No active session'
                      : 'New captures use the active session',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}