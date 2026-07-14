import 'package:flutter/material.dart';

import '../models/capture.dart';
import '../models/session.dart';
import '../models/session_summary.dart';
import '../models/workspace.dart';
import '../services/session_summary_service.dart';

class SessionHistoryDialog extends StatefulWidget {
  final List<NexusSession> sessions;
  final List<Capture> captures;
  final List<Workspace> workspaces;

  const SessionHistoryDialog({
    super.key,
    required this.sessions,
    required this.captures,
    required this.workspaces,
  });

  @override
  State<SessionHistoryDialog> createState() =>
      _SessionHistoryDialogState();
}

class _SessionHistoryDialogState
    extends State<SessionHistoryDialog> {
  final SessionSummaryService _summaryService =
      SessionSummaryService();

  final Map<String, SessionSummary> _summaries = {};
  final Set<String> _loadingSessionIds = {};
  final Map<String, String> _errors = {};

  String _workspaceName(String? workspaceId) {
    if (workspaceId == null) {
      return 'General';
    }

    for (final workspace in widget.workspaces) {
      if (workspace.id == workspaceId) {
        return workspace.name;
      }
    }

    return 'Unknown workspace';
  }

  List<Capture> _capturesForSession(String sessionId) {
    return widget.captures
        .where(
          (capture) => capture.sessionId == sessionId,
        )
        .toList();
  }

  String _formatTimestamp(String timestamp) {
    final parsed = DateTime.tryParse(timestamp);

    if (parsed == null) {
      return timestamp;
    }

    final local = parsed.toLocal();

    final month =
        local.month.toString().padLeft(2, '0');
    final day =
        local.day.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour =
        local.hour.toString().padLeft(2, '0');
    final minute =
        local.minute.toString().padLeft(2, '0');

    return '$month/$day/$year $hour:$minute';
  }

  Future<void> _generateSummary(
    NexusSession session,
  ) async {
    setState(() {
      _loadingSessionIds.add(session.id);
      _errors.remove(session.id);
    });

    try {
      final summary = await _summaryService.generateSummary(
        session.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _summaries[session.id] = summary;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errors[session.id] =
            'Could not generate the session summary.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingSessionIds.remove(session.id);
        });
      }
    }
  }

  Widget _buildSummary(
    SessionSummary summary,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Session Intelligence',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(summary.summary),
          const SizedBox(height: 12),
          Text(
            '${summary.captureCount} linked captures',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (summary.actionItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Action Items',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            ...summary.actionItems.map(
              (item) => _buildBullet(
                icon: Icons.check_box_outlined,
                text: item,
              ),
            ),
          ],
          if (summary.questions.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Questions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            ...summary.questions.map(
              (question) => _buildBullet(
                icon: Icons.help_outline,
                text: question,
              ),
            ),
          ],
          if (summary.referencedItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Referenced Items',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: summary.referencedItems
                  .map(
                    (item) => Chip(
                      label: Text(item),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBullet({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderedSessions = [...widget.sessions]
      ..sort(
        (a, b) => b.startedAt.compareTo(a.startedAt),
      );

    return AlertDialog(
      title: const Text('Session History'),
      content: SizedBox(
        width: 760,
        height: 560,
        child: orderedSessions.isEmpty
            ? const Center(
                child: Text(
                  'No sessions have been created yet.',
                ),
              )
            : ListView.builder(
                itemCount: orderedSessions.length,
                itemBuilder: (context, index) {
                  final session = orderedSessions[index];

                  final sessionCaptures =
                      _capturesForSession(session.id);

                  final summary =
                      _summaries[session.id];

                  final isLoading =
                      _loadingSessionIds.contains(
                    session.id,
                  );

                  final error = _errors[session.id];

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
                          const EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        16,
                      ),
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
                        Row(
                          children: [
                            FilledButton.icon(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      _generateSummary(
                                        session,
                                      );
                                    },
                              icon: isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.auto_awesome,
                                    ),
                              label: Text(
                                summary == null
                                    ? 'Generate Summary'
                                    : 'Regenerate Summary',
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (error != null)
                              Expanded(
                                child: Text(
                                  error,
                                  style: const TextStyle(
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (summary != null)
                          _buildSummary(summary),
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
                              'No captures were attached '
                              'to this session.',
                            ),
                          )
                        else
                          ...sessionCaptures.map(
                            (capture) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              leading: const Icon(
                                Icons.notes_outlined,
                              ),
                              title: Text(capture.title),
                              subtitle: Text(
                                capture.content,
                              ),
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
          onPressed: () =>
              Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}