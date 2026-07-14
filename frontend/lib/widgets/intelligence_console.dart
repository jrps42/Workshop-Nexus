import 'package:flutter/material.dart';

import '../models/intelligence_state.dart';

class IntelligenceConsole extends StatelessWidget {
  final IntelligenceState state;
  final VoidCallback onRefresh;

  const IntelligenceConsole({
    super.key,
    required this.state,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final confidencePercent = state.confidence == null
        ? null
        : (state.confidence! * 100).round();

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.psychology_outlined),
          SizedBox(width: 10),
          Text('Intelligence Console'),
        ],
      ),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ConsoleCard(
                title: 'Current Context',
                icon: Icons.adjust,
                children: [
                  _ConsoleValue(
                    label: 'Workspace',
                    value: state.workspaceName ?? 'None — Inbox',
                  ),
                  const SizedBox(height: 10),
                  _ConsoleValue(
                    label: 'Session',
                    value: state.sessionName ?? 'None',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ConsoleCard(
                title: 'Last Routing Decision',
                icon: Icons.route_outlined,
                children: [
                  _ConsoleValue(
                    label: 'Destination',
                    value:
                        state.destination ?? 'No decision recorded',
                  ),
                  const SizedBox(height: 10),
                  _ConsoleValue(
                    label: 'Confidence',
                    value: confidencePercent == null
                        ? 'Not available'
                        : '$confidencePercent%',
                  ),
                  const SizedBox(height: 10),
                  _ConsoleValue(
                    label: 'Reason',
                    value:
                        state.reason ?? 'No routing decision yet.',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ConsoleCard(
                title: 'Actions',
                icon: Icons.build_outlined,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Context'),
                    ),
                  ),
                ],
              ),
            ],
          ),
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

class _ConsoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _ConsoleCard({
    required this.title,
    required this.icon,
    required this.children,
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
                Icon(icon),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ConsoleValue extends StatelessWidget {
  final String label;
  final String value;

  const _ConsoleValue({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}