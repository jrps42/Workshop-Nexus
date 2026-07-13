class RoutingDecision {
  final String? workspaceId;
  final String? sessionId;
  final String destination;
  final double confidence;
  final String reason;

  const RoutingDecision({
    required this.workspaceId,
    required this.sessionId,
    required this.destination,
    required this.confidence,
    required this.reason,
  });

  factory RoutingDecision.fromJson(
    Map<String, dynamic> json,
  ) {
    return RoutingDecision(
      workspaceId: json["workspace_id"],
      sessionId: json["session_id"],
      destination: json["destination"],
      confidence: json["confidence"].toDouble(),
      reason: json["reason"],
    );
  }
}