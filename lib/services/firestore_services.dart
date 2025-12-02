import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject_model.dart';
import '../models/knowledge_model.dart';
import '../models/rule_model.dart';

class FirestoreServices {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Stream<List<SubjectModel>> streamSubjects() {
    return _db.collection('subjects').snapshots().map(
      (snap) => snap.docs.map((d) {
        final Map<String, dynamic> data = d.data();
        return SubjectModel.fromMap(d.id, data);
      }).toList(),
    );
  }

  Future<List<SubjectModel>> getSubjectsOnce() async {
    final snap = await _db.collection('subjects').get();
    return snap.docs.map((d) {
      final Map<String, dynamic> data = d.data();
      return SubjectModel.fromMap(d.id, data);
    }).toList();
  }

  /// CREATE subject
  Future<void> createSubject(String name) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _db.collection('subjects').doc(id).set({
      'nama': name,
    });
  }

  /// UPDATE subject
  Future<void> updateSubject(String id, String name) async {
    await _db.collection('subjects').doc(id).update({
      'nama': name,
    });
  }

  /// DELETE subject
  Future<void> deleteSubject(String id) async {
    await _db.collection('subjects').doc(id).delete();
  }

  // --------------------------------------------------
  // KNOWLEDGE / MATERIALS
  // --------------------------------------------------
  Future<List<KnowledgeModel>> getKnowledgeBySubject(String subjectId) async {
    final snap = await _db
        .collection('knowledge')
        .where('subject_id', isEqualTo: subjectId)
        .get();

    return snap.docs.map((d) {
      final Map<String, dynamic> data = d.data();
      return KnowledgeModel.fromMap(d.id, data);
    }).toList();
  }

  Future<List<KnowledgeModel>> getKnowledgeBySubjectAndType(
    String subjectId,
    String jenis,
  ) async {
    final snap = await _db
        .collection('knowledge')
        .where('subject_id', isEqualTo: subjectId)
        .where('jenis', isEqualTo: jenis)
        .get();

    return snap.docs.map((d) {
      final Map<String, dynamic> data = d.data();
      return KnowledgeModel.fromMap(d.id, data);
    }).toList();
  }

  Future<KnowledgeModel?> getKnowledgeById(String id) async {
    final doc = await _db.collection('knowledge').doc(id).get();
    if (!doc.exists) return null;

    final data = doc.data() as Map<String, dynamic>;
    return KnowledgeModel.fromMap(doc.id, data);
  }

  /// CREATE material
  Future<void> createKnowledge(KnowledgeModel k) async {
    await _db.collection('knowledge').doc(k.id).set(k.toMap());
  }

  /// UPDATE material
  Future<void> updateKnowledge(KnowledgeModel k) async {
    await _db.collection('knowledge').doc(k.id).update(k.toMap());
  }

  /// DELETE material
  Future<void> deleteKnowledge(String id) async {
    await _db.collection('knowledge').doc(id).delete();
  }

  // --------------------------------------------------
  // RULES
  // --------------------------------------------------
  Future<List<RuleModel>> getRulesBySubject(String subjectId) async {
    final snap = await _db
        .collection('rules')
        .where('subject_id', isEqualTo: subjectId)
        .get();

    return snap.docs.map((d) {
      final Map<String, dynamic> data = d.data();
      return RuleModel.fromMap(d.id, data);
    }).toList();
  }

  Future<List<RuleModel>> getAllRules() async {
    final snap = await _db.collection('rules').get();

    return snap.docs.map((d) {
      final Map<String, dynamic> data = d.data();
      return RuleModel.fromMap(d.id, data);
    }).toList();
  }

  /// CREATE rule
  Future<void> createRule(RuleModel r) async {
    await _db.collection('rules').doc(r.id).set(r.toMap());
  }

  /// UPDATE rule
  Future<void> updateRule(RuleModel r) async {
    await _db.collection('rules').doc(r.id).update(r.toMap());
  }

  /// DELETE rule
  Future<void> deleteRule(String id) async {
    await _db.collection('rules').doc(id).delete();
  }

  // --------------------------------------------------
  // RECOMMENDATION ENGINE
  // --------------------------------------------------
  Future<RuleModel?> getRecommendationForMaterial(
    String materialId, {
    String? subjectId,
  }) async {
    Query query = _db
        .collection('rules')
        .where('material_id', isEqualTo: materialId);

    if (subjectId != null) {
      query = query.where('subject_id', isEqualTo: subjectId);
    }

    final snapExact = await query.limit(1).get();

    if (snapExact.docs.isNotEmpty) {
      final data = snapExact.docs.first.data() as Map<String, dynamic>;
      return RuleModel.fromMap(snapExact.docs.first.id, data);
    }

    // fallback fuzzy search
    final all = await getAllRules();

    for (var r in all) {
      if ((r.kondisi.toLowerCase().contains(materialId.toLowerCase()) ||
              r.rekomendasi.toLowerCase().contains(materialId.toLowerCase())) &&
          (subjectId == null || r.subjectId == subjectId)) {
        return r;
      }
    }

    return null;
  }

  Future<List<KnowledgeModel>> searchKnowledge(String keyword) async {
    final lower = keyword.toLowerCase();
    final snap = await _db.collection('knowledge').get();

    return snap.docs
        .map((d) {
          final Map<String, dynamic> data = d.data();
          return KnowledgeModel.fromMap(d.id, data);
        })
        .where((k) =>
            k.judul.toLowerCase().contains(lower) ||
            k.konten.toLowerCase().contains(lower))
        .toList();
  }
}
