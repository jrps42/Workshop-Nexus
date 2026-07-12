import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/capture.dart';
import 'api.dart';

class CaptureService {
  Future<List<Capture>> getCaptures() async {
    final response = await http.get(
      Uri.parse('${Api.baseUrl}/captures'),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load captures: ${response.statusCode}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map(
          (item) => Capture.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<Capture> createCapture({
    required String title,
    required String content,
    String? workspaceId,
    String? sessionId,
  }) async {
    final response = await http.post(
      Uri.parse('${Api.baseUrl}/captures'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'content': content,
        'capture_type': 'text',
        'workspace_id': workspaceId,
        'session_id': sessionId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to create capture: ${response.statusCode}',
      );
    }

    return Capture.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteCapture(String captureId) async {
    final response = await http.delete(
      Uri.parse('${Api.baseUrl}/captures/$captureId'),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to delete capture: ${response.statusCode}',
      );
    }
  }

  Future<Capture> assignWorkspace({
    required String captureId,
    required String? workspaceId,
  }) async {
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

    return Capture.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}