import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/session.dart';
import 'api.dart';

class SessionService {
  Future<List<NexusSession>> getSessions() async {
    final response = await http.get(
      Uri.parse('${Api.baseUrl}/sessions'),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load sessions: ${response.statusCode}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map(
          (item) => NexusSession.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<NexusSession> createSession({
    required String title,
    String? summary,
    String? location,
    String? workspaceId,
  }) async {
    final response = await http.post(
      Uri.parse('${Api.baseUrl}/sessions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'summary': summary,
        'location': location,
        'workspace_id': workspaceId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to create session: ${response.statusCode}',
      );
    }

    return NexusSession.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<NexusSession> completeSession(
    String sessionId,
  ) async {
    final response = await http.post(
      Uri.parse(
        '${Api.baseUrl}/sessions/$sessionId/complete',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to complete session: ${response.statusCode}',
      );
    }

    return NexusSession.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}