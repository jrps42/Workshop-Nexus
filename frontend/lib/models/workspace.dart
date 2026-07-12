class Workspace {
  final String id;
  final String name;
  final String? description;

  const Workspace({
    required this.id,
    required this.name,
    this.description,
  });

  factory Workspace.fromJson(Map<String, dynamic> json) {
    return Workspace(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }
}