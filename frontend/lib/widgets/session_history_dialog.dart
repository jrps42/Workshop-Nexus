import 'package:flutter/material.dart';

import '../models/capture.dart';
import '../models/session.dart';
import '../models/workspace.dart';

class SessionHistoryDialog extends StatelessWidget {
  final List<NexusSession> sessions;
  final List<Capture> captures;
  final List<Workspace> workspaces;

  const SessionHistoryDialog({
    super.key,
    required this.sessions,
    required this.captures,
    required this.workspaces,
  });

  String _workspaceName(String? workspaceId) {
    if (workspaceId == null) {
      return 'General';
    }

    for (final workspace in workspaces) {
      if (workspace.id == workspaceId) {
        return workspace.name;
      }
    }

    return 'Unknown workspace';
  }

  List<Capture> _capturesForSession(String sessionId) {
    return captures
        .where((capture) => capture.sessionId == sessionId)
        .toList();
  }

  String _formatTimestamp(String timestamp) {
    final parsed = DateTime.tryParse(timestamp);

    if (parsed == null) {
      return timestamp;
    }

    final local = parsed.toLocal();

    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$month/$day/$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final orderedSessions = [...sessions]
      ..sort(
        (a, b) => b.startedAt.compareTo(a.startedAt),
      );

    return AlertDialog(
      title: const Text('Session History'),
      content: SizedBox(
        width: 700,
        height: 520,
        child: orderedSessions.isEmpty
            ? const Center(
                child: Text('No sessions have been created yet.'),
              )
            : ListView.builder(
                itemCount: orderedSessions.length,
                itemBuilder: (context, index) {
                  final session = orderedSessions[index];
                  final sessionCaptures =
                      _capturesForSession(session.id);

                  return Card(
                    child: ExpansionTile(
                      leading: Icon(
                        session.isActive
                            ? Icons.play_circle_outline
                            : Icons.check_circle_outline,
                      ),
                      title: Text(session.title),
                      subtitle: Text(
                        '${_workspaceName(session.workspaceId)} · '
                        '${session.status} · '
                        '${sessionCaptures.length} captures',
                      ),
                      childrenPadding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Started: '
                            '${_formatTimestamp(session.startedAt)}',
                          ),
                        ),
                        if (session.endedAt != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Ended: '
                              '${_formatTimestamp(session.endedAt!)}',
                            ),
                          ),
                        if (session.location != null &&
                            session.location!.isNotEmpty)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Location: ${session.location}',
                            ),
                          ),
                        if (session.summary != null &&
                            session.summary!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(session.summary!),
                          ),
                        ],
                        const SizedBox(height: 12),
                        const Divider(),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Captures',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (sessionCaptures.isEmpty)
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'No captures were attached to this session.',
                            ),
                          )
                        else
                          ...sessionCaptures.map(
                            (capture) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              leading:
                                  const Icon(Icons.notes_outlined),
                              title: Text(capture.title),
                              subtitle: Text(capture.content),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}