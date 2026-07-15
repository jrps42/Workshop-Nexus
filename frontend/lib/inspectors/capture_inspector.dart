import 'package:flutter/material.dart';

import '../models/capture.dart';
import '../models/session.dart';
import '../models/workspace.dart';
import 'inspector_sheet.dart';

class CaptureInspector extends StatelessWidget {
  final Capture capture;
  final Workspace? workspace;
  final NexusSession? session;

  const CaptureInspector({
    super.key,
    required this.capture,
    required this.workspace,
    required this.session,
  });

  String _formatCreatedAt(String timestamp) {
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
    return InspectorSheet(
      title: 'Capture Inspector',
      icon: Icons.description_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InspectorSection(
            title: 'Capture',
            children: [
              _InspectorValue(
                label: 'Title',
                value: capture.title,
              ),
              const SizedBox(height: 16),
              _InspectorValue(
                label: 'Content',
                value: capture.content,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InspectorSection(
            title: 'Metadata',
            children: [
              _InspectorValue(
                label: 'Created',
                value: _formatCreatedAt(
                  capture.createdAt,
                ),
              ),
              const SizedBox(height: 16),
              _InspectorValue(
                label: 'Capture Type',
                value: capture.captureType,
              ),
              const SizedBox(height: 16),
              _InspectorValue(
                label: 'Workspace',
                value: workspace?.name ?? 'Inbox',
              ),
              const SizedBox(height: 16),
              _InspectorValue(
                label: 'Session',
                value: session?.title ?? 'None',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _InspectorSection(
            title: 'Routing',
            children: [
              Text(
                'Detailed routing evidence will appear here '
                'in a later inspector update.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InspectorSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InspectorSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InspectorValue extends StatelessWidget {
  final String label;
  final String value;

  const _InspectorValue({
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
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}