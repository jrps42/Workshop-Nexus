class Capture {
  final String id;
  final String title;
  final String content;
  final String captureType;
  final String createdAt;
  final String? workspaceId;
  final String? sessionId;

  const Capture({
    required this.id,
    required this.title,
    required this.content,
    required this.captureType,
    required this.createdAt,
    this.workspaceId,
    this.sessionId,
  });

  factory Capture.fromJson(Map<String, dynamic> json) {
    return Capture(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      captureType: json['capture_type'] as String,
      createdAt: json['created_at'] as String,
      workspaceId: json['workspace_id'] as String?,
      sessionId: json['session_id'] as String?,
    );
  }
}