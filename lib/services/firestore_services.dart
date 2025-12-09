import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject_model.dart';
import '../models/knowledge_model.dart';
import '../models/rule_model.dart';
import '../models/user_model.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import 'expert_engine.dart';

class FirestoreServices {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==================== SUBJECTS ====================
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

  Future<List<SubjectModel>> getAllSubjects() => getSubjectsOnce();

  Future<void> createSubject(String name) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _db.collection('subjects').doc(id).set({
      'nama': name,
    });
  }

  Future<void> updateSubject(String id, String name) async {
    await _db.collection('subjects').doc(id).update({
      'nama': name,
    });
  }

  Future<void> deleteSubject(String id) async {
    await _db.collection('subjects').doc(id).delete();
  }

  // ==================== KNOWLEDGE ====================
  Future<List<KnowledgeModel>> getAllKnowledge() async {
    final snap = await _db.collection('knowledge').get();
    return snap.docs.map((d) {
      final Map<String, dynamic> data = d.data();
      return KnowledgeModel.fromMap(d.id, data);
    }).toList();
  }

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

  Future<void> createKnowledge(KnowledgeModel k) async {
    await _db.collection('knowledge').doc(k.id).set(k.toMap());
  }

  Future<void> updateKnowledge(KnowledgeModel k) async {
    await _db.collection('knowledge').doc(k.id).update(k.toMap());
  }

  Future<void> deleteKnowledge(String id) async {
    await _db.collection('knowledge').doc(id).delete();
  }

  // ==================== RULES ====================
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

  Future<void> createRule(RuleModel r) async {
    await _db.collection('rules').doc(r.id).set(r.toMap());
  }

  Future<void> updateRule(RuleModel r) async {
    await _db.collection('rules').doc(r.id).update(r.toMap());
  }

  Future<void> deleteRule(String id) async {
    await _db.collection('rules').doc(id).delete();
  }

  Future<RuleModel?> getRecommendationForMaterial(
    String materialId, {
    String? subjectId,
  }) async {
    // 1. Fetch the Material details first.
    // We need the TITLE (Judul) because matching text is better than matching IDs.
    final knowledgeDoc = await _db.collection('knowledge').doc(materialId).get();
    
    if (!knowledgeDoc.exists) return null;

    final Map<String, dynamic> kData = knowledgeDoc.data() as Map<String, dynamic>;
    final String materialTitle = (kData['judul'] ?? '').toString();

    // 2. Fetch all rules (filtering by subject from DB is faster)
    List<RuleModel> candidates;
    if (subjectId != null) {
      candidates = await getRulesBySubject(subjectId);
    } else {
      candidates = await getAllRules();
    }

    // 3. USE EXPERT ENGINE - STEP A: Exact ID Match
    // (If you linked them manually in Admin Panel)
    final exactMatch = ExpertEngine.inferFromMaterial(materialId, candidates);
    if (exactMatch != null) {
      print("DEBUG: Found by Exact ID Match");
      return exactMatch;
    }

    // 4. USE EXPERT ENGINE - STEP B: Fuzzy Text Match
    // Pass the Material TITLE (e.g., "Algebra") to see if any Rule mentions "Algebra"
    final scoredRules = ExpertEngine.scoreRulesByCondition(materialTitle, candidates);

    if (scoredRules.isNotEmpty) {
      // Return the highest scoring rule
      final bestMatch = scoredRules.first;
      print("DEBUG: Found by Text Match (Score: ${bestMatch.score})");
      return bestMatch.rule;
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

  // ==================== USERS ====================
  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.id).set(user.toMap());
  }

  Future<UserModel?> getUserById(String id) async {
    final doc = await _db.collection('users').doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(doc.id, data);
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final snap = await _db.collection('users').where('email', isEqualTo: email).limit(1).get();
    if (snap.docs.isEmpty) return null;
    final data = snap.docs.first.data();
    return UserModel.fromMap(snap.docs.first.id, data);
  }

  Future<UserModel?> getUserByUsername(String username) async {
    final snap = await _db.collection('users').where('username', isEqualTo: username).limit(1).get();
    if (snap.docs.isEmpty) return null;
    final data = snap.docs.first.data();
    return UserModel.fromMap(snap.docs.first.id, data);
  }

  Future<void> updateUser(UserModel user) async {
    await _db.collection('users').doc(user.id).update(user.toMap());
  }

  Future<void> deleteUser(String id) async {
    await _db.collection('users').doc(id).delete();
  }

  Future<List<UserModel>> getAllUsers() async {
    final snap = await _db.collection('users').get();
    return snap.docs.map((d) {
      final Map<String, dynamic> data = d.data();
      return UserModel.fromMap(d.id, data);
    }).toList();
  }

  Future<List<UserModel>> getAllAdmins() async {
    final snap = await _db.collection('users').where('role', isEqualTo: 'admin').get();
    return snap.docs.map((d) {
      final Map<String, dynamic> data = d.data();
      return UserModel.fromMap(d.id, data);
    }).toList();
  }

  Future<void> updateUserRole(String id, String newRole) async {
    await _db.collection('users').doc(id).update({'role': newRole});
  }

  // ==================== CONVERSATIONS ====================
  Future<ConversationModel?> getOrCreateConversation(
    String userId,
    String adminId,
    String userName,
    String adminName,
  ) async {
    final snap = await _db
        .collection('conversations')
        .where('user_id', isEqualTo: userId)
        .where('admin_id', isEqualTo: adminId)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      final data = snap.docs.first.data();
      return ConversationModel.fromMap(snap.docs.first.id, data);
    }

    final id = '${userId}_${adminId}_${DateTime.now().millisecondsSinceEpoch}';
    final conversation = ConversationModel(
      id: id,
      userId: userId,
      adminId: adminId,
      userName: userName,
      adminName: adminName,
      lastMessage: '',
      lastMessageTime: DateTime.now(),
      unreadCount: 0,
    );

    await _db.collection('conversations').doc(id).set(conversation.toMap());
    return conversation;
  }

  Stream<List<ConversationModel>> streamUserConversations(String userId) {
    return _db
        .collection('conversations')
        .where('user_id', isEqualTo: userId)
        .orderBy('last_message_time', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final Map<String, dynamic> data = d.data();
              return ConversationModel.fromMap(d.id, data);
            }).toList());
  }

  Stream<List<ConversationModel>> streamAdminConversations(String adminId) {
    return _db
        .collection('conversations')
        .where('admin_id', isEqualTo: adminId)
        .orderBy('last_message_time', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final Map<String, dynamic> data = d.data();
              return ConversationModel.fromMap(d.id, data);
            }).toList());
  }

  // ==================== MESSAGES ====================
  Future<void> sendMessage(MessageModel message) async {
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    
    await _db
        .collection('conversations')
        .doc(message.conversationId)
        .collection('messages')
        .doc(messageId)
        .set(message.toMap());

    await _db.collection('conversations').doc(message.conversationId).update({
      'last_message': message.message,
      'last_message_time': message.timestamp,
    });
  }

  Stream<List<MessageModel>> streamMessages(String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final Map<String, dynamic> data = d.data();
              return MessageModel.fromMap(d.id, data);
            }).toList());
  }

  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    final snap = await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('sender_id', isNotEqualTo: userId)
        .where('is_read', isEqualTo: false)
        .get();

    for (var doc in snap.docs) {
      await doc.reference.update({'is_read': true});
    }

    await _db.collection('conversations').doc(conversationId).update({
      'unread_count': 0,
    });
  }
}