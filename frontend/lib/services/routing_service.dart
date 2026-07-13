import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/routing_decision.dart';

const String _baseUrl = 'http://127.0.0.1:8000';

class RoutingService {
  Future<RoutingDecision> suggest({
    required String content,
    String? activeWorkspaceId,
    String? activeSessionId,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/routing/suggest'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'content': content,
        'active_workspace_id': activeWorkspaceId,
        'active_session_id': activeSessionId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Routing request failed: ${response.statusCode}',
      );
    }

    return RoutingDecision.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}