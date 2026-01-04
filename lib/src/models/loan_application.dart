/// Model representing a loan application.
class LoanApplication {
  final String? id;
  final String userId;
  final String nationalId;
  final int age;
  final bool hasExistingProject;
  final int projectMonths;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LoanApplication({
    this.id,
    required this.userId,
    required this.nationalId,
    required this.age,
    required this.hasExistingProject,
    required this.projectMonths,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
  });

  /// Creates a [LoanApplication] from JSON.
  factory LoanApplication.fromJson(Map<String, dynamic> json) {
    return LoanApplication(
      id: json['id'] as String?,
      userId: json['userId'] as String,
      nationalId: json['nationalId'] as String,
      age: json['age'] as int,
      hasExistingProject: json['hasExistingProject'] as bool,
      projectMonths: json['projectMonths'] as int,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Converts [LoanApplication] to JSON.
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'nationalId': nationalId,
      'age': age,
      'hasExistingProject': hasExistingProject,
      'projectMonths': projectMonths,
      'status': status,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Creates a copy of [LoanApplication] with updated fields.
  LoanApplication copyWith({
    String? id,
    String? userId,
    String? nationalId,
    int? age,
    bool? hasExistingProject,
    int? projectMonths,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LoanApplication(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nationalId: nationalId ?? this.nationalId,
      age: age ?? this.age,
      hasExistingProject: hasExistingProject ?? this.hasExistingProject,
      projectMonths: projectMonths ?? this.projectMonths,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
