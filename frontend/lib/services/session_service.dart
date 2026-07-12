class NexusSession {
  final String id;
  final String title;
  final String? summary;
  final String? location;
  final String? workspaceId;
  final String status;
  final String startedAt;
  final String? endedAt;

  const NexusSession({
    required this.id,
    required this.title,
    required this.status,
    required this.startedAt,
    this.summary,
    this.location,
    this.workspaceId,
    this.endedAt,
  });

  bool get isActive => status == 'active';

  factory NexusSession.fromJson(Map<String, dynamic> json) {
    return NexusSession(
      id: json['id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String?,
      location: json['location'] as String?,
      workspaceId: json['workspace_id'] as String?,
      status: json['status'] as String,
      startedAt: json['started_at'] as String,
      endedAt: json['ended_at'] as String?,
    );
  }
}