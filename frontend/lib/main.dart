import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

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

  Capture({
    required this.id,
    required this.title,
    required this.content,
    required this.captureType,
    required this.createdAt,
  });

  factory Capture.fromJson(Map<String, dynamic> json) {
    return Capture(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      captureType: json['capture_type'],
      createdAt: json['created_at'],
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

  final String _apiBaseUrl = 'http://127.0.0.1:8000';

  List<Capture> _captures = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadCaptures();

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

  Future<void> _loadCaptures() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse('$_apiBaseUrl/captures'));

      if (response.statusCode != 200) {
        throw Exception('Failed to load captures');
      }

      final List<dynamic> data = jsonDecode(response.body);

      setState(() {
        _captures = data.map((item) => Capture.fromJson(item)).toList();
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Could not connect to Nexus backend.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCapture() async {
    final content = _controller.text.trim();

    if (content.isEmpty || _isSaving) {
      return;
    }

    final title = content.length > 40 ? '${content.substring(0, 40)}...' : content;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/captures'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'content': content,
          'capture_type': 'text',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to save capture');
      }

      _controller.clear();
      await _loadCaptures();

      setState(() {
        _statusMessage = 'Saved ✓';
      });

      Timer(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _statusMessage = null;
          });
          _captureFocusNode.requestFocus();
        }
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Could not save capture.';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _deleteCapture(String captureId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/captures/$captureId'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete capture');
      }

      await _loadCaptures();
    } catch (_) {
      setState(() {
        _errorMessage = 'Could not delete capture.';
      });
    }
  }

  void _clearCaptureBox() {
    _controller.clear();
    _captureFocusNode.requestFocus();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final isControlPressed = HardwareKeyboard.instance.isControlPressed;

    if (isControlPressed && event.logicalKey == LogicalKeyboardKey.enter) {
      _saveCapture();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _clearCaptureBox();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Workshop Nexus',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
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
                      hintText: 'Type a thought, idea, task, note, or project detail...',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveCapture,
                      child: Text(_isSaving ? 'Saving...' : 'Save Capture'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _clearCaptureBox,
                      child: const Text('Clear'),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _loadCaptures,
                      tooltip: 'Refresh',
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
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
                const Text(
                  'Recent Captures',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: _captures.length,
                          itemBuilder: (context, index) {
                            final capture = _captures[index];

                            return Card(
                              child: ListTile(
                                title: Text(capture.title),
                                subtitle: Text(capture.content),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _deleteCapture(capture.id),
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
    );
  }
}