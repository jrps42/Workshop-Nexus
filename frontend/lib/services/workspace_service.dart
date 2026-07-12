import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/workspace.dart';
import 'api.dart';

class WorkspaceService {
  Future<List<Workspace>> getWorkspaces() async {
    final response = await http.get(
      Uri.parse('${Api.baseUrl}/workspaces'),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load workspaces: ${response.statusCode}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map(
          (item) => Workspace.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}