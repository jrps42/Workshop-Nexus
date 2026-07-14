import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/capture.dart';
import '../models/routing_decision.dart';
import '../models/session.dart';
import '../models/workspace.dart';
import '../services/capture_service.dart';
import '../services/routing_service.dart';
import '../services/session_service.dart';
import '../services/workspace_service.dart';
import '../widgets/capture_editor.dart';
import '../widgets/capture_list.dart';
import '../widgets/create_session_dialog.dart';
import '../widgets/current_context_panel.dart';
import '../widgets/routing_feedback_banner.dart';
import '../widgets/session_history_dialog.dart';
import '../widgets/workspace_sidebar.dart';

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
  final RoutingService _routingService = RoutingService();

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

  RoutingDecision? _lastRoutingDecision;
  String _lastRoutingDestinationName = 'Inbox';

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

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _statusMessage = null;

      if (ignoreContext) {
        _lastRoutingDecision = null;
        _lastRoutingDestinationName = 'Inbox';
      }
    });

    try {
      String? workspaceId;
      String? sessionId;
      String destination = 'inbox';
      RoutingDecision? routingDecision;

      if (!ignoreContext) {
        routingDecision = await _routingService.suggest(
          content: content,
          activeWorkspaceId: _activeWorkspaceId,
          activeSessionId: _activeSessionId,
        );

        workspaceId = routingDecision.workspaceId;
        sessionId = routingDecision.sessionId;
        destination = routingDecision.destination;
      }

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

      setState(() {
        _lastRoutingDecision = routingDecision;

        if (routingDecision == null) {
          _lastRoutingDestinationName = 'Inbox';
        } else if (routingDecision.sessionId != null) {
          _lastRoutingDestinationName = _sessionName(
            routingDecision.sessionId,
          );
        } else {
          _lastRoutingDestinationName = _workspaceName(
            routingDecision.workspaceId,
          );
        }
      });

      if (ignoreContext) {
        _showTemporaryStatus('Saved → Inbox ✓');
      } else {
        switch (destination) {
          case 'active_session':
            _showTemporaryStatus(
              'Saved → $_lastRoutingDestinationName ✓',
            );
            break;

          case 'active_workspace':
          case 'workspace':
            _showTemporaryStatus(
              'Saved → $_lastRoutingDestinationName ✓',
            );
            break;

          default:
            _showTemporaryStatus('Saved → Inbox ✓');
        }
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Could not route or save capture.';
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

  Future<void> _showSessionHistory() async {
    await showDialog<void>(
      context: context,
      builder: (context) => SessionHistoryDialog(
        sessions: _sessions,
        captures: _captures,
        workspaces: _workspaces,
      ),
    );

    if (mounted) {
      _captureFocusNode.requestFocus();
    }
  }

  void _showTemporaryStatus(String message) {
    setState(() {
      _statusMessage = message;
    });

    Timer(const Duration(seconds: 2), () {
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

    if (keyboard.isControlPressed &&
        keyboard.isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.enter) {
      _saveCapture(ignoreContext: true);
      return KeyEventResult.handled;
    }

    if (keyboard.isControlPressed &&
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

  String _sessionName(String? sessionId) {
    if (sessionId == null) {
      return 'Inbox';
    }

    for (final session in _sessions) {
      if (session.id == sessionId) {
        return session.title;
      }
    }

    return 'Unknown session';
  }

  @override
  Widget build(BuildContext context) {
    final visibleCaptures = _visibleCaptures;

    final heading = _selectedWorkspaceFilterId == null
        ? 'All Captures'
        : _selectedWorkspaceFilterId == 'inbox'
            ? 'Inbox'
            : _workspaceName(_selectedWorkspaceFilterId);

    return Scaffold(
      body: Row(
        children: [
          WorkspaceSidebar(
            workspaces: _workspaces,
            isLoading: _isLoadingWorkspaces,
            selectedFilterId: _selectedWorkspaceFilterId,
            onFilterSelected: (filterId) {
              setState(() {
                _selectedWorkspaceFilterId = filterId;
              });
            },
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
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
                      const SizedBox(height: 20),
                      CurrentContextPanel(
                        workspaces: _workspaces,
                        availableSessions: _availableSessions,
                        isLoadingSessions: _isLoadingSessions,
                        activeWorkspaceId: _activeWorkspaceId,
                        activeSessionId: _activeSessionId,
                        onWorkspaceChanged:
                            _selectActiveWorkspace,
                        onSessionChanged: (sessionId) {
                          setState(() {
                            _activeSessionId = sessionId;
                          });

                          _captureFocusNode.requestFocus();
                        },
                        onLeaveContext: _leaveContext,
                        onStartSession: _createSession,
                        onCompleteSession:
                            _completeActiveSession,
                        onShowSessionHistory:
                            _showSessionHistory,
                      ),
                      const SizedBox(height: 20),
                      CaptureEditor(
                        controller: _controller,
                        focusNode: _captureFocusNode,
                        isSaving: _isSaving,
                        statusMessage: _statusMessage,
                        errorMessage: _errorMessage,
                        onKeyEvent: _handleKeyEvent,
                        onSave: _saveCapture,
                        onSaveToInbox: () {
                          _saveCapture(ignoreContext: true);
                        },
                        onClear: _clearCaptureBox,
                        onRefresh: _loadInitialData,
                      ),
                      const SizedBox(height: 12),
                      RoutingFeedbackBanner(
                        decision: _lastRoutingDecision,
                        destinationName:
                            _lastRoutingDestinationName,
                      ),
                      if (_lastRoutingDecision != null)
                        const SizedBox(height: 12),
                      Text(
                        heading,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: CaptureList(
                          captures: visibleCaptures,
                          workspaces: _workspaces,
                          isLoading: _isLoadingCaptures,
                          onWorkspaceChanged:
                              _assignWorkspace,
                          onDelete: _deleteCapture,
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