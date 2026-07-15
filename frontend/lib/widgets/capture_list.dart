import 'package:flutter/material.dart';

import '../models/capture.dart';
import '../models/workspace.dart';
import 'capture_tile.dart';

class CaptureList extends StatelessWidget {
  final List<Capture> captures;
  final List<Workspace> workspaces;
  final bool isLoading;

  final ValueChanged<Capture> onCaptureSelected;

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
    required this.onCaptureSelected,
    required this.onWorkspaceChanged,
    required this.onDelete,
  });

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

        return CaptureTile(
          capture: capture,
          workspaces: workspaces,
          onTap: () => onCaptureSelected(capture),
          onWorkspaceChanged: (workspaceId) {
            onWorkspaceChanged(
              capture.id,
              workspaceId,
            );
          },
          onDelete: () => onDelete(capture.id),
        );
      },
    );
  }
}