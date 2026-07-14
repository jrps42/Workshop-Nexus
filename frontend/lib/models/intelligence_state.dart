class IntelligenceState {
  final String? workspaceName;
  final String? sessionName;

  final String? destination;
  final double? confidence;
  final String? reason;

  const IntelligenceState({
    this.workspaceName,
    this.sessionName,
    this.destination,
    this.confidence,
    this.reason,
  });
}