import 'user.dart';

class WorkspaceMembership {
  final int id;
  final User user;
  final String role;

  const WorkspaceMembership({
    required this.id,
    required this.user,
    required this.role,
  });

  factory WorkspaceMembership.fromJson(Map<String, dynamic> json) {
    return WorkspaceMembership(
      id: json['id'] as int,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      role: json['role'] as String,
    );
  }
}

class Workspace {
  final int id;
  final String name;
  final User owner;
  final List<WorkspaceMembership> memberships;

  const Workspace({
    required this.id,
    required this.name,
    required this.owner,
    required this.memberships,
  });

  factory Workspace.fromJson(Map<String, dynamic> json) {
    return Workspace(
      id: json['id'] as int,
      name: json['name'] as String,
      owner: User.fromJson(json['owner'] as Map<String, dynamic>),
      memberships: (json['memberships'] as List<dynamic>)
          .map((m) => WorkspaceMembership.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}
