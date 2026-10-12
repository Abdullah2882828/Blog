import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/project.dart';
import '../services/firebase_service.dart';

/// شاشة إدارة المشاريع والملفات.
///
/// تتيح للمستخدم:
/// * عرض قائمة المشاريع (مجلدات) والملفات داخل كل مشروع.
/// * إنشاء مشروع جديد (مجلد).
/// * استيراد ملف من الجهاز أو من صورة (OCR غير مدمج هنا).
/// * تصدير ملف/مشروع عبر مشاركة النظام.
/// * حذف وتعديل أسماء المشاريع/الملفات.
class ProjectManagerScreen extends StatefulWidget {
  const ProjectManagerScreen({Key? key}) : super(key: key);

  @override
  State<ProjectManagerScreen> createState() => _ProjectManagerScreenState();
}

class _ProjectManagerScreenState extends State<ProjectManagerScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Project> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    try {
      final projects = await _firebaseService.fetchUserProjects();
      setState(() => _projects = projects);
    } catch (e) {
      // ignore: avoid_print
      print('خطأ في تحميل المشاريع: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تحميل المشاريع')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// إنشاء مشروع جديد (مجلد) بإسم عشوائي أو يحدده المستخدم.
  Future<void> _createProject() async {
    final TextEditingController controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إنشاء مشروع جديد'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'اسم المشروع',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final newProject = Project(
        id: const Uuid().v4(),
        name: result,
        files: [],
        createdAt: DateTime.now(),
      );
      await _firebaseService.addProject(newProject);
      await _loadProjects();
    }
  }

  /// استيراد ملف من الجهاز وإضافته إلى مشروع مختار.
  Future<void> _importFile(Project project) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null) return; // المستخدم ألغى الاختيار.
    final PlatformFile file = result.files.first;
    final Uint8List? bytes = file.bytes;
    // إذا لم تتوفر الـ bytes (مثلاً عند اختيار من التخزين الخارجي) نقرأ من المسار.
    final Uint8List fileData = bytes ??
        await File(file.path!).readAsBytes();

    // حفظ الملف مؤقتاً داخل دليل التطبيق لتوحيد المسار.
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String newPath = '${appDir.path}/${project.id}_${file.name}';
    final File newFile = File(newPath);
    await newFile.writeAsBytes(fileData);

    // تحديث نموذج المشروع.
    final updatedProject = project.copyWith(
      files: List.from(project.files)
        ..add(FileMetadata(
          id: const Uuid().v4(),
          name: file.name,
          path: newPath,
          size: file.size,
          createdAt: DateTime.now(),
        )),
    );
    await _firebaseService.updateProject(updatedProject);
    await _loadProjects();
  }

  /// مشاركة (تصدير) ملف عبر Share Plus.
  Future<void> _shareFile(FileMetadata fileMeta) async {
    final File file = File(fileMeta.path);
    if (!await file.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الملف غير موجود')),
      );
      return;
    }
    await Share.shareXFiles([
      XFile(file.path, name: fileMeta.name),
    ], text: 'ملف من مشروع ${fileMeta.name}');
  }

  /// حذف ملف من المشروع.
  Future<void> _deleteFile(Project project, FileMetadata fileMeta) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الملف'),
        content: Text('هل تريد حذف "${fileMeta.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirm != true) return;

    // حذف الملف من التخزين المحلي إذا كان موجوداً.
    final File file = File(fileMeta.path);
    if (await file.exists()) await file.delete();

    final updatedProject = project.copyWith(
      files: List.from(project.files)..removeWhere((f) => f.id == fileMeta.id),
    );
    await _firebaseService.updateProject(updatedProject);
    await _loadProjects();
  }

  /// حذف مشروع بالكامل.
  Future<void> _deleteProject(Project project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المشروع'),
        content: Text('سيتم حذف جميع الملفات داخل المشروع "${project.name}". هل تريد المتابعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirm != true) return;

    // حذف جميع الملفات المخزنة محلياً.
    for (final fileMeta in project.files) {
      final File f = File(fileMeta.path);
      if (await f.exists()) await f.delete();
    }
    await _firebaseService.deleteProject(project.id);
    await _loadProjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المشاريع'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
              ? const Center(child: Text('لا توجد مشاريع. اضغط "+" لإنشاء مشروع جديد.'))
              : ListView.builder(
                  itemCount: _projects.length,
                  itemBuilder: (ctx, index) {
                    final project = _projects[index];
                    return ExpansionTile(
                      key: ValueKey(project.id),
                      title: Text(project.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteProject(project),
                      ),
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: project.files.length,
                          itemBuilder: (c, i) {
                            final file = project.files[i];
                            return ListTile(
                              leading: const Icon(Icons.insert_drive_file),
                              title: Text(file.name),
                              subtitle: Text('${(file.size / 1024).toStringAsFixed(1)} ك ب'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.share),
                                    onPressed: () => _shareFile(file),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteFile(project, file),
                                  ),
                                ],
                              ),
                              onTap: () async {
                                // فتح الملف في محرر النصوص إذا كان نصاً.
                                final ext = file.name.split('.').last.toLowerCase();
                                if (['dart', 'js', 'py', 'java', 'txt', 'json', 'md'].contains(ext)) {
                                  final content = await File(file.path).readAsString();
                                  Navigator.pushNamed(context, '/code_editor', arguments: {
                                    'projectId': project.id,
                                    'fileId': file.id,
                                    'initialContent': content,
                                    'fileName': file.name,
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('نوع الملف غير مدعوم للعرض')),
                                  );
                                }
                              },
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.add),
                          title: const Text('استيراد ملف'),
                          onTap: () => _importFile(project),
                        ),
                      ],
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createProject,
        icon: const Icon(Icons.create_new_folder),
        label: const Text('مشروع جديد'),
      ),
    );
  }
}

/**
 * نماذج البيانات المستخدمة في هذه الشاشة.
 * تم تعريفها في lib/models/project.dart، لكن نعيد تعريف الفئات الضرورية
 * هنا لتقليل الاعتمادية على ملفات غير موجودة في هذا السياق.
 */
class Project {
  final String id;
  final String name;
  final List<FileMetadata> files;
  final DateTime createdAt;

  Project({
    required this.id,
    required this.name,
    required this.files,
    required this.createdAt,
  });

  Project copyWith({
    String? id,
    String? name,
    List<FileMetadata>? files,
    DateTime? createdAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      files: files ?? this.files,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      files: (map['files'] as List<dynamic>?)
              ?.map((e) => FileMetadata.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt,
      'files': files.map((e) => e.toMap()).toList(),
    };
  }
}

class FileMetadata {
  final String id;
  final String name;
  final String path;
  final int size; // بالبايت
  final DateTime createdAt;

  FileMetadata({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.createdAt,
  });

  FileMetadata copyWith({
    String? id,
    String? name,
    String? path,
    int? size,
    DateTime? createdAt,
  }) {
    return FileMetadata(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      size: size ?? this.size,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory FileMetadata.fromMap(Map<String, dynamic> map) {
    return FileMetadata(
      id: map['id'] as String,
      name: map['name'] as String,
      path: map['path'] as String,
      size: map['size'] as int,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'size': size,
      'createdAt': createdAt,
    };
  }
}

/**
 * خدمة Firebase مبسطة لتخزين المشاريع.
 * في التطبيق الحقيقي يجب إضافة استثناءات وإدارة الأخطاء بشكل أدق.
 */
class FirebaseService {
  // افترض وجود FirebaseFirestore instance جاهز.
  final _firestore = FirebaseFirestore.instance;
  final String _userId = 'CURRENT_USER_UID'; // يجب استبداله بـ FirebaseAuth.instance.currentUser.uid

  Future<List<Project>> fetchUserProjects() async {
    final snapshot = await _firestore.collection('users').doc(_userId).collection('projects').get();
    return snapshot.docs.map((doc) => Project.fromMap(doc.data())).toList();
  }

  Future<void> addProject(Project project) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('projects')
        .doc(project.id)
        .set(project.toMap());
  }

  Future<void> updateProject(Project project) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('projects')
        .doc(project.id)
        .update(project.toMap());
  }

  Future<void> deleteProject(String projectId) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('projects')
        .doc(projectId)
        .delete();
  }
}
