import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'models/workspace.dart';
import 'services/api.dart';
import 'services/workspace_service.dart';

void main() {
  runApp(const NexusApp());
}

class NexusApp extends StatelessWidget {
  const NexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workshop Nexus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const CaptureHomePage(),
    );
  }
}

class Capture {
  final String id;
  final String title;
  final String content;
  final String captureType;
  final String createdAt;
  final String? workspaceId;

  const Capture({
    required this.id,
    required this.title,
    required this.content,
    required this.captureType,
    required this.createdAt,
    this.workspaceId,
  });

  factory Capture.fromJson(Map<String, dynamic> json) {
    return Capture(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      captureType: json['capture_type'] as String,
      createdAt: json['created_at'] as String,
      workspaceId: json['workspace_id'] as String?,
    );
  }
}

class CaptureHomePage extends StatefulWidget {
  const CaptureHomePage({super.key});

  @override
  State<CaptureHomePage> createState() => _CaptureHomePageState();
}

class _CaptureHomePageState extends State<CaptureHomePage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _captureFocusNode = FocusNode();
  final WorkspaceService _workspaceService = WorkspaceService();

  List<Capture> _captures = [];
  List<Workspace> _workspaces = [];

  bool _isLoadingCaptures = false;
  bool _isLoadingWorkspaces = false;
  bool _isSaving = false;

  String? _selectedWorkspaceFilterId;
  String? _errorMessage;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _captureFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadCaptures(),
      _loadWorkspaces(),
    ]);
  }

  Future<void> _loadCaptures() async {
    setState(() {
      _isLoadingCaptures = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${Api.baseUrl}/captures'),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load captures: ${response.statusCode}',
        );
      }

      final List<dynamic> data = jsonDecode(response.body);

      if (!mounted) {
        return;
      }

      setState(() {
        _captures = data
            .map(
              (item) => Capture.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Could not connect to Nexus backend.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCaptures = false;
        });
      }
    }
  }

  Future<void> _loadWorkspaces() async {
    setState(() {
      _isLoadingWorkspaces = true;
      _errorMessage = null;
    });

    try {
      final workspaces = await _workspaceService.getWorkspaces();

      if (!mounted) {
        return;
      }

      setState(() {
        _workspaces = workspaces;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Could not load workspaces.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWorkspaces = false;
        });
      }
    }
  }

  Future<void> _saveCapture() async {
    final content = _controller.text.trim();

    if (content.isEmpty || _isSaving) {
      return;
    }

    final title = content.length > 40
        ? '${content.substring(0, 40)}...'
        : content;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${Api.baseUrl}/captures'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'content': content,
          'capture_type': 'text',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to save capture: ${response.statusCode}',
        );
      }

      _controller.clear();
      await _loadCaptures();

      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = 'Saved ✓';
      });

      Timer(const Duration(seconds: 1), () {
        if (!mounted) {
          return;
        }

        setState(() {
          _statusMessage = null;
        });

        _captureFocusNode.requestFocus();
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Could not save capture.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteCapture(String captureId) async {
    try {
      final response = await http.delete(
        Uri.parse('${Api.baseUrl}/captures/$captureId'),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to delete capture: ${response.statusCode}',
        );
      }

      await _loadCaptures();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Could not delete capture.';
      });
    }
  }

  Future<void> _assignWorkspace(
    String captureId,
    String? workspaceId,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse(
          '${Api.baseUrl}/captures/$captureId/workspace',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'workspace_id': workspaceId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to assign workspace: ${response.statusCode}',
        );
      }

      await _loadCaptures();

      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = workspaceId == null
            ? 'Moved to Inbox ✓'
            : 'Workspace updated ✓';
      });

      Timer(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _statusMessage = null;
          });
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Could not update workspace.';
      });
    }
  }

  void _clearCaptureBox() {
    _controller.clear();
    _captureFocusNode.requestFocus();
  }

  KeyEventResult _handleKeyEvent(
    FocusNode node,
    KeyEvent event,
  ) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final isControlPressed =
        HardwareKeyboard.instance.isControlPressed;

    if (isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.enter) {
      _saveCapture();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _clearCaptureBox();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  List<Capture> get _visibleCaptures {
    if (_selectedWorkspaceFilterId == null) {
      return _captures;
    }

    if (_selectedWorkspaceFilterId == 'inbox') {
      return _captures
          .where((capture) => capture.workspaceId == null)
          .toList();
    }

    return _captures
        .where(
          (capture) =>
              capture.workspaceId == _selectedWorkspaceFilterId,
        )
        .toList();
  }

  String _workspaceName(String? workspaceId) {
    if (workspaceId == null) {
      return 'Inbox';
    }

    for (final workspace in _workspaces) {
      if (workspace.id == workspaceId) {
        return workspace.name;
      }
    }

    return 'Unknown workspace';
  }

  String? _safeWorkspaceValue(String? workspaceId) {
  if (workspaceId == null) {
    return null;
  }

  final workspaceExists = _workspaces.any(
    (workspace) => workspace.id == workspaceId,
  );

  return workspaceExists ? workspaceId : null;
}
  @override
  Widget build(BuildContext context) {
    final visibleCaptures = _visibleCaptures;

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 250,
            child: Material(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
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
                      selected:
                          _selectedWorkspaceFilterId == null,
                      onTap: () {
                        setState(() {
                          _selectedWorkspaceFilterId = null;
                        });
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.inbox_outlined),
                      title: const Text('Inbox'),
                      selected:
                          _selectedWorkspaceFilterId == 'inbox',
                      onTap: () {
                        setState(() {
                          _selectedWorkspaceFilterId = 'inbox';
                        });
                      },
                    ),
                    const Divider(),
                    if (_isLoadingWorkspaces)
                      const Center(
                        child: CircularProgressIndicator(),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: _workspaces.length,
                          itemBuilder: (context, index) {
                            final workspace =
                                _workspaces[index];

                            return ListTile(
                              leading:
                                  const Icon(Icons.folder_outlined),
                              title: Text(workspace.name),
                              subtitle:
                                  workspace.description == null
                                      ? null
                                      : Text(
                                          workspace.description!,
                                          maxLines: 2,
                                          overflow:
                                              TextOverflow.ellipsis,
                                        ),
                              selected:
                                  _selectedWorkspaceFilterId ==
                                      workspace.id,
                              onTap: () {
                                setState(() {
                                  _selectedWorkspaceFilterId =
                                      workspace.id;
                                });
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 820),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Workshop Nexus',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'What would you like to remember?',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      Focus(
                        focusNode: _captureFocusNode,
                        onKeyEvent: _handleKeyEvent,
                        child: TextField(
                          controller: _controller,
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
                            onPressed:
                                _isSaving ? null : _saveCapture,
                            child: Text(
                              _isSaving
                                  ? 'Saving...'
                                  : 'Save Capture',
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: _clearCaptureBox,
                            child: const Text('Clear'),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _loadInitialData,
                            tooltip: 'Refresh',
                            icon: const Icon(Icons.refresh),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_statusMessage != null)
                        Text(
                          _statusMessage!,
                          style:
                              const TextStyle(color: Colors.green),
                        ),
                      if (_errorMessage != null)
                        Text(
                          _errorMessage!,
                          style:
                              const TextStyle(color: Colors.red),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedWorkspaceFilterId == null
                            ? 'All Captures'
                            : _selectedWorkspaceFilterId == 'inbox'
                                ? 'Inbox'
                                : _workspaceName(
                                    _selectedWorkspaceFilterId,
                                  ),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _isLoadingCaptures
                            ? const Center(
                                child:
                                    CircularProgressIndicator(),
                              )
                            : visibleCaptures.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No captures here yet.',
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount:
                                        visibleCaptures.length,
                                    itemBuilder:
                                        (context, index) {
                                      final capture =
                                          visibleCaptures[index];

                                      return Card(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.all(
                                            12,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .stretch,
                                            children: [
                                              Text(
                                                capture.title,
                                                style:
                                                    const TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 6,
                                              ),
                                              Text(
                                                capture.content,
                                              ),
                                              const SizedBox(
                                                height: 12,
                                              ),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child:
                                                        DropdownButtonFormField<
                                                            String?>(
                                                      initialValue: _safeWorkspaceValue(capture.workspaceId),
                                                      decoration:
                                                          const InputDecoration(
                                                        labelText:
                                                            'Workspace',
                                                        border:
                                                            OutlineInputBorder(),
                                                        isDense: true,
                                                      ),
                                                      items: [
                                                        const DropdownMenuItem<
                                                            String?>(
                                                          value: null,
                                                          child: Text(
                                                            'Inbox',
                                                          ),
                                                        ),
                                                        ..._workspaces
                                                            .map(
                                                          (
                                                            workspace,
                                                          ) =>
                                                              DropdownMenuItem<
                                                                  String?>(
                                                            value:
                                                                workspace
                                                                    .id,
                                                            child: Text(
                                                              workspace
                                                                  .name,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                      onChanged:
                                                          (workspaceId) {
                                                        _assignWorkspace(
                                                          capture.id,
                                                          workspaceId,
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: 8,
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons
                                                          .delete_outline,
                                                    ),
                                                    tooltip:
                                                        'Delete capture',
                                                    onPressed: () =>
                                                        _deleteCapture(
                                                      capture.id,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}