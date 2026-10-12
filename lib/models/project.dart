/// نموذج بيانات المشروع والملفات المرتبطة.
class Project {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ProjectFile> files;

  Project({
    required this.id,
    required this.name,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ProjectFile>? files,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        files = files ?? [];

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      files: (json['files'] as List<dynamic>?)
              ?.map((e) => ProjectFile.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'files': files.map((e) => e.toJson()).toList(),
      };

  Project copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ProjectFile>? files,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      files: files ?? List<ProjectFile>.from(this.files),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Project &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        _listEquals(other.files, files);
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        createdAt,
        updatedAt,
        Object.hashAll(files),
      );

  bool _listEquals(List<ProjectFile> a, List<ProjectFile> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// نموذج بيانات الملف داخل المشروع.
class ProjectFile {
  final String id;
  final String name;
  final String? path; // مسار الملف محلياً أو على السحابة
  final String? content; // محتوى الملف (اختياري)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProjectFile({
    required this.id,
    required this.name,
    this.path,
    this.content,
    this.createdAt,
    this.updatedAt,
  });

  factory ProjectFile.fromJson(Map<String, dynamic> json) {
    return ProjectFile(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String?,
      content: json['content'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'path': path,
        'content': content,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  ProjectFile copyWith({
    String? id,
    String? name,
    String? path,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectFile(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProjectFile &&
        other.id == id &&
        other.name == name &&
        other.path == path &&
        other.content == content &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        path,
        content,
        createdAt,
        updatedAt,
      );
}
