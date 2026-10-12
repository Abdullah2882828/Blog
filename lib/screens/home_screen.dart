import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/project.dart';
import '../services/firebase_service.dart';
import 'code_editor_screen.dart';
import 'ai_chat_screen.dart';
import 'project_manager_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Project> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await FirebaseService.instance.getUserProjects();
      setState(() {
        _projects = projects;
        _isLoading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('خطأ في جلب المشاريع: $e');
      setState(() => _isLoading = false);
    }
  }

  void _openProject(Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CodeEditorScreen(project: project),
      ),
    ).then((_) => _loadProjects()); // تحديث القائمة بعد العودة
  }

  void _createNewProject() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProjectManagerScreen()),
    ).then((_) => _loadProjects());
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AIChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الصفحة الرئيسية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: _loadProjects,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
              ? const Center(child: Text('لا توجد مشاريع حالياً'))
              : ListView.builder(
                  itemCount: _projects.length,
                  itemBuilder: (context, index) {
                    final project = _projects[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.folder, color: Colors.amber),
                        title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('آخر تعديل: ${DateFormat.yMMMd().add_jm().format(project.lastModified)}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openProject(project),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewProject,
        icon: const Icon(Icons.add),
        label: const Text('مشروع جديد'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.code), label: 'المحرر'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'المحادثة'),
          BottomNavigationBarItem(icon: Icon(Icons.folder_open), label: 'المشاريع'),
        ],
        currentIndex: 2, // الشاشة الحالية هي "المشاريع"
        onTap: (index) {
          switch (index) {
            case 0:
              // الانتقال إلى محرر الكود الفارغ (يمكن تعديل حسب الحاجة)
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CodeEditorScreen()))
                  .then((_) => _loadProjects());
              break;
            case 1:
              _openChat();
              break;
            case 2:
              // بالفعل في الشاشة الحالية
              break;
          }
        },
      ),
    );
  }
}
