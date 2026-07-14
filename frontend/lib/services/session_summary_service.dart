import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/session_summary.dart';

const String _baseUrl = 'http://127.0.0.1:8000';

class SessionSummaryService {
  Future<SessionSummary> generateSummary(
    String sessionId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/sessions/$sessionId/summary',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to generate session summary: '
        '${response.statusCode}',
      );
    }

    return SessionSummary.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}