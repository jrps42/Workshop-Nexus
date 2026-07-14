class SessionSummary {
  final String sessionId;
  final String sessionTitle;
  final int captureCount;
  final String summary;
  final List<String> actionItems;
  final List<String> questions;
  final List<String> referencedItems;

  const SessionSummary({
    required this.sessionId,
    required this.sessionTitle,
    required this.captureCount,
    required this.summary,
    required this.actionItems,
    required this.questions,
    required this.referencedItems,
  });

  factory SessionSummary.fromJson(
    Map<String, dynamic> json,
  ) {
    return SessionSummary(
      sessionId: json['session_id'] as String,
      sessionTitle: json['session_title'] as String,
      captureCount: json['capture_count'] as int,
      summary: json['summary'] as String,
      actionItems: List<String>.from(
        json['action_items'] as List<dynamic>,
      ),
      questions: List<String>.from(
        json['questions'] as List<dynamic>,
      ),
      referencedItems: List<String>.from(
        json['referenced_items'] as List<dynamic>,
      ),
    );
  }
}