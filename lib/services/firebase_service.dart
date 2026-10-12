import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/project.dart';

/// خدمة موحدة للتعامل مع Firebase Authentication و Cloud Firestore.
///
/// توفر هذه الخدمة جميع عمليات المصادقة الأساسية (تسجيل الدخول،
/// التسجيل، تسجيل الخروج، وإعادة تعيين كلمة المرور) بالإضافة إلى عمليات
/// CRUD لمشاريع المستخدم في Firestore.
class FirebaseService {
  // ---------- Singleton ----------
  FirebaseService._privateConstructor();
  static final FirebaseService instance = FirebaseService._privateConstructor();

  // ---------- Firebase instances ----------
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------- Authentication ----------

  /// يعيد المستخدم الحالي إذا كان مسجلاً الدخول، وإلا يعيد `null`.
  User? get currentUser => _auth.currentUser;

  /// تسجيل الدخول باستخدام البريد الإلكتروني وكلمة المرور.
  ///
  /// يُرجى التعامل مع الاستثناءات في الطبقة المستدعية لتقديم رسائل
  /// مناسبة للمستخدم.
  Future<User?> signInWithEmail({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase signIn error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// إنشاء حساب جديد باستخدام البريد الإلكتروني وكلمة المرور.
  Future<User?> registerWithEmail({required String email, required String password}) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase register error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// إرسال بريد إلكتروني لإعادة تعيين كلمة المرور.
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase password reset error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// تسجيل الخروج.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ---------- Firestore Project CRUD ----------

  /// مرجع مجموعة المشاريع في Firestore.
  CollectionReference get _projectsRef => _firestore.collection('projects');

  /// إنشاء مشروع جديد.
  ///
  /// يتم تخزين المشروع تحت معرف فريد يُنشئه Firestore تلقائيًا إذا لم يُحدَّد `id` داخل النموذج.
  Future<void> createProject(Project project) async {
    try {
      final docRef = project.id != null ? _projectsRef.doc(project.id) : _projectsRef.doc();
      final data = project.copyWith(id: docRef.id).toMap();
      await docRef.set(data);
    } catch (e, stack) {
      debugPrint('Error creating project: $e');
      if (kDebugMode) print(stack);
      rethrow;
    }
  }

  /// الحصول على تدفق (Stream) للمشاريع الخاصة بالمستخدم المحدد.
  ///
  /// يُعيد قائمة المشاريع مرتبة حسب تاريخ الإنشاء (الأحدث أولاً).
  Stream<List<Project>> getProjectsStream(String userId) {
    return _projectsRef
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Project.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList());
  }

  /// جلب مشروع واحد بناءً على معرّفه.
  Future<Project?> getProjectById(String projectId) async {
    try {
      final doc = await _projectsRef.doc(projectId).get();
      if (!doc.exists) return null;
      return Project.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching project $projectId: $e');
      rethrow;
    }
  }

  /// تحديث مشروع موجود.
  Future<void> updateProject(Project project) async {
    if (project.id == null) {
      throw ArgumentError('Project id cannot be null for update operation');
    }
    try {
      await _projectsRef.doc(project.id).update(project.toMap());
    } catch (e) {
      debugPrint('Error updating project ${project.id}: $e');
      rethrow;
    }
  }

  /// حذف مشروع من قاعدة البيانات.
  Future<void> deleteProject(String projectId) async {
    try {
      await _projectsRef.doc(projectId).delete();
    } catch (e) {
      debugPrint('Error deleting project $projectId: $e');
      rethrow;
    }
  }
}
