import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/capture.dart';
import '../models/session.dart';
import '../models/workspace.dart';
import '../services/capture_service.dart';
import '../services/session_service.dart';
import '../services/workspace_service.dart';
import '../widgets/create_session_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _captureFocusNode = FocusNode();

  final CaptureService _captureService = CaptureService();
  final WorkspaceService _workspaceService = WorkspaceService();
  final SessionService _sessionService = SessionService();

  List<Capture> _captures = [];
  List<Workspace> _workspaces = [];
  List<NexusSession> _sessions = [];

  bool _isLoadingCaptures = false;
  bool _isLoadingWorkspaces = false;
  bool _isLoadingSessions = false;
  bool _isSaving = false;

  String? _selectedWorkspaceFilterId;
  String? _activeWorkspaceId;
  String? _activeSessionId;

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
      _loadSessions(),
    ]);
  }

  Future<void> _loadCaptures() async {
    setState(() {
      _isLoadingCaptures = true;
      _errorMessage = null;
    });

    try {
      final captures = await _captureService.getCaptures();

      if (!mounted) {
        return;
      }

      setState(() {
        _captures = captures;
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

  Future<void> _loadSessions() async {
    setState(() {
      _isLoadingSessions = true;
      _errorMessage = null;
    });

    try {
      final sessions = await _sessionService.getSessions();

      if (!mounted) {
        return;
      }

      setState(() {
        _sessions = sessions;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Could not load sessions.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSessions = false;
        });
      }
    }
  }

  Future<void> _saveCapture({
    bool ignoreContext = false,
  }) async {
    final content = _controller.text.trim();

    if (content.isEmpty || _isSaving) {
      return;
    }

    final title = content.length > 40
        ? '${content.substring(0, 40)}...'
        : content;

    final workspaceId = ignoreContext ? null : _activeWorkspaceId;
    final sessionId = ignoreContext ? null : _activeSessionId;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      await _captureService.createCapture(
        title: title,
        content: content,
        workspaceId: workspaceId,
        sessionId: sessionId,
      );

      _controller.clear();
      await _loadCaptures();

      if (!mounted) {
        return;
      }

      _showTemporaryStatus(
        ignoreContext
            ? 'Saved to Inbox ✓'
            : _activeSessionId != null
                ? 'Saved to active session ✓'
                : _activeWorkspaceId != null
                    ? 'Saved to workspace ✓'
                    : 'Saved to Inbox ✓',
      );
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
      await _captureService.deleteCapture(captureId);
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
      await _captureService.assignWorkspace(
        captureId: captureId,
        workspaceId: workspaceId,
      );

      await _loadCaptures();

      if (!mounted) {
        return;
      }

      _showTemporaryStatus(
        workspaceId == null
            ? 'Moved to Inbox ✓'
            : 'Workspace updated ✓',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Could not update workspace.';
      });
    }
  }

  Future<void> _createSession() async {
    final result = await showDialog<CreateSessionResult>(
      context: context,
      builder: (context) => const CreateSessionDialog(),
    );

    if (result == null || !mounted) {
      _captureFocusNode.requestFocus();
      return;
    }

    try {
      final session = await _sessionService.createSession(
        title: result.title,
        summary: result.summary,
        location: result.location,
        workspaceId: _activeWorkspaceId,
      );

      await _loadSessions();

      if (!mounted) {
        return;
      }

      setState(() {
        _activeSessionId = session.id;
      });

      _showTemporaryStatus('Session started ✓');
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Could not start session.';
      });
    }
  }

  Future<void> _completeActiveSession() async {
    final sessionId = _activeSessionId;

    if (sessionId == null) {
      return;
    }

    try {
      await _sessionService.completeSession(sessionId);
      await _loadSessions();

      if (!mounted) {
        return;
      }

      setState(() {
        _activeSessionId = null;
      });

      _showTemporaryStatus('Session completed ✓');
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Could not complete session.';
      });
    }
  }

  void _showTemporaryStatus(String message) {
    setState(() {
      _statusMessage = message;
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
  }

  void _clearCaptureBox() {
    _controller.clear();
    _captureFocusNode.requestFocus();
  }

  void _leaveContext() {
    setState(() {
      _activeWorkspaceId = null;
      _activeSessionId = null;
    });

    _showTemporaryStatus('Context cleared ✓');
  }

  void _selectActiveWorkspace(String? workspaceId) {
    setState(() {
      _activeWorkspaceId = workspaceId;

      final selectedSessionStillMatches = _sessions.any(
        (session) =>
            session.id == _activeSessionId &&
            session.workspaceId == workspaceId &&
            session.isActive,
      );

      if (!selectedSessionStillMatches) {
        _activeSessionId = null;
      }
    });

    _captureFocusNode.requestFocus();
  }

  KeyEventResult _handleKeyEvent(
    FocusNode node,
    KeyEvent event,
  ) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final keyboard = HardwareKeyboard.instance;
    final isControlPressed = keyboard.isControlPressed;
    final isShiftPressed = keyboard.isShiftPressed;

    if (isControlPressed &&
        isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.enter) {
      _saveCapture(ignoreContext: true);
      return KeyEventResult.handled;
    }

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

  List<NexusSession> get _availableSessions {
    return _sessions.where((session) {
      if (!session.isActive) {
        return false;
      }

      if (_activeWorkspaceId == null) {
        return session.workspaceId == null;
      }

      return session.workspaceId == _activeWorkspaceId;
    }).toList();
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

    final exists = _workspaces.any(
      (workspace) => workspace.id == workspaceId,
    );

    return exists ? workspaceId : null;
  }

  @override
  Widget build(BuildContext context) {
    final visibleCaptures = _visibleCaptures;

    return Scaffold(
      body: Row(
        children: [
          _buildWorkspaceSidebar(),
          const VerticalDivider(width: 1),
          Expanded(
            child: _buildMainContent(visibleCaptures),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceSidebar() {
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
                selected: _selectedWorkspaceFilterId == null,
                onTap: () {
                  setState(() {
                    _selectedWorkspaceFilterId = null;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.inbox_outlined),
                title: const Text('Inbox'),
                selected: _selectedWorkspaceFilterId == 'inbox',
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
                      final workspace = _workspaces[index];

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
    );
  }

  Widget _buildMainContent(List<Capture> visibleCaptures) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Workshop Nexus',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _buildContextPanel(),
              const SizedBox(height: 20),
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
                    onPressed: _isSaving ? null : _saveCapture,
                    child: Text(
                      _isSaving
                          ? 'Saving...'
                          : 'Save Capture',
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _isSaving
                        ? null
                        : () {
                            _saveCapture(ignoreContext: true);
                          },
                    child: const Text('Save to Inbox'),
                  ),
                  const SizedBox(width: 8),
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
              const SizedBox(height: 6),
              const Text(
                'Ctrl+Enter: save with context · '
                'Ctrl+Shift+Enter: save to Inbox',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              if (_statusMessage != null)
                Text(
                  _statusMessage!,
                  style: const TextStyle(color: Colors.green),
                ),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
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
                child: _buildCaptureList(visibleCaptures),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextPanel() {
    final availableSessions = _availableSessions;

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
                  onPressed: _activeWorkspaceId == null &&
                          _activeSessionId == null
                      ? null
                      : _leaveContext,
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
                    initialValue: _activeWorkspaceId,
                    decoration: const InputDecoration(
                      labelText: 'Active Workspace',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No workspace — Inbox'),
                      ),
                      ..._workspaces.map(
                        (workspace) =>
                            DropdownMenuItem<String?>(
                          value: workspace.id,
                          child: Text(workspace.name),
                        ),
                      ),
                    ],
                    onChanged: _selectActiveWorkspace,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _activeSessionId,
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
                        (session) =>
                            DropdownMenuItem<String?>(
                          value: session.id,
                          child: Text(session.title),
                        ),
                      ),
                    ],
                    onChanged: _isLoadingSessions
                        ? null
                        : (sessionId) {
                            setState(() {
                              _activeSessionId = sessionId;
                            });

                            _captureFocusNode.requestFocus();
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _createSession,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start New Session'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _activeSessionId == null
                      ? null
                      : _completeActiveSession,
                  icon: const Icon(Icons.stop),
                  label: const Text('Complete Active Session'),
                ),
                const Spacer(),
                Text(
                  _activeSessionId == null
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

  Widget _buildCaptureList(List<Capture> captures) {
    if (_isLoadingCaptures) {
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
                          ..._workspaces.map(
                            (workspace) =>
                                DropdownMenuItem<String?>(
                              value: workspace.id,
                              child: Text(workspace.name),
                            ),
                          ),
                        ],
                        onChanged: (workspaceId) {
                          _assignWorkspace(
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
                      onPressed: () {
                        _deleteCapture(capture.id);
                      },
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