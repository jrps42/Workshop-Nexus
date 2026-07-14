import 'package:flutter/material.dart';

import '../models/workspace.dart';

class WorkspaceSidebar extends StatelessWidget {
  final List<Workspace> workspaces;
  final bool isLoading;
  final String? selectedFilterId;

  final ValueChanged<String?> onFilterSelected;
  final VoidCallback onOpenIntelligence;

  const WorkspaceSidebar({
    super.key,
    required this.workspaces,
    required this.isLoading,
    required this.selectedFilterId,
    required this.onFilterSelected,
    required this.onOpenIntelligence,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Material(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Workspaces',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.all_inbox),
                title: const Text('All Captures'),
                selected: selectedFilterId == null,
                onTap: () => onFilterSelected(null),
              ),
              ListTile(
                leading: const Icon(Icons.inbox_outlined),
                title: const Text('Inbox'),
                selected: selectedFilterId == 'inbox',
                onTap: () => onFilterSelected('inbox'),
              ),
              const Divider(),
              if (isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: workspaces.length,
                    itemBuilder: (context, index) {
                      final workspace = workspaces[index];

                      return ListTile(
                        leading:
                            const Icon(Icons.folder_outlined),
                        title: Text(workspace.name),
                        subtitle: workspace.description == null
                            ? null
                            : Text(
                                workspace.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                        selected:
                            selectedFilterId == workspace.id,
                        onTap: () {
                          onFilterSelected(workspace.id);
                        },
                      );
                    },
                  ),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.psychology_outlined),
                title: const Text('Intelligence'),
                subtitle: const Text('Inspect Nexus decisions'),
                onTap: onOpenIntelligence,
              ),
            ],
          ),
        ),
      ),
    );
  }
}