// lib/services/storage_service.dart
//
// Firebase Firestore database structure:
//
//  users/{userId}/
//    ├── activeConversationId  (field on user doc)
//    └── conversations/{conversationId}   (sub-collection)
//          id, title, createdAt, updatedAt
//          └── messages/{messageId}       (sub-collection)
//                id, content, role, timestamp, status

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class StorageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Auth -----------------------------------------------------------------

  /// Signs in anonymously so every device gets a unique userId
  /// without requiring email/password from the user.
  Future<void> init() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  String get _userId {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    return uid;
  }

  // --- Firestore collection refs --------------------------------------------

  CollectionReference<Map<String, dynamic>> get _convCol =>
      _db.collection('users').doc(_userId).collection('conversations');

  CollectionReference<Map<String, dynamic>> _msgCol(String convId) =>
      _convCol.doc(convId).collection('messages');

  // --- Load conversations ---------------------------------------------------

  Future<List<Conversation>> loadConversations() async {
    try {
      final snap = await _convCol.orderBy('updatedAt', descending: true).get();
      final conversations = <Conversation>[];

      for (final doc in snap.docs) {
        final data = doc.data();
        final messages = await _loadMessages(doc.id);
        conversations.add(Conversation(
          id: doc.id,
          title: data['title'] as String? ?? 'New Chat',
          messages: messages,
          createdAt: _toDateTime(data['createdAt']),
          updatedAt: _toDateTime(data['updatedAt']),
        ));
      }

      return conversations;
    } catch (e) {
      return [];
    }
  }

  Future<List<Message>> _loadMessages(String convId) async {
    try {
      final snap =
          await _msgCol(convId).orderBy('timestamp', descending: false).get();
      return snap.docs.map((d) => _messageFromDoc(d.data())).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Save conversations ---------------------------------------------------

  Future<void> saveConversations(List<Conversation> conversations) async {
    for (final conv in conversations) {
      await _upsertConversation(conv);
    }
  }

  Future<void> _upsertConversation(Conversation conv) async {
    // 1. Write / merge conversation document
    await _convCol.doc(conv.id).set({
      'id': conv.id,
      'title': conv.title,
      'createdAt': Timestamp.fromDate(conv.createdAt),
      'updatedAt': Timestamp.fromDate(conv.updatedAt),
    }, SetOptions(merge: true));

    // 2. Write all messages in a batch (max 500 ops per batch)
    if (conv.messages.isEmpty) return;

    final batch = _db.batch();
    for (final msg in conv.messages) {
      final ref = _msgCol(conv.id).doc(msg.id);
      batch.set(ref, _messageToMap(msg), SetOptions(merge: true));
    }
    await batch.commit();
  }

  // --- Active conversation ID -----------------------------------------------

  Future<String?> loadActiveConversationId() async {
    try {
      final doc = await _db.collection('users').doc(_userId).get();
      return doc.data()?['activeConversationId'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveActiveConversationId(String? id) async {
    await _db.collection('users').doc(_userId).set(
      {'activeConversationId': id},
      SetOptions(merge: true),
    );
  }

  // --- Delete conversation --------------------------------------------------

  Future<void> deleteConversation(String convId) async {
    final msgs = await _msgCol(convId).get();
    final batch = _db.batch();
    for (final doc in msgs.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_convCol.doc(convId));
    await batch.commit();
  }

  // --- Real-time stream -----------------------------------------------------

  /// Stream of conversations — auto-updates UI when Firestore changes.
  Stream<List<Conversation>> conversationsStream() {
    return _convCol
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .asyncMap((snap) async {
      final list = <Conversation>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final messages = await _loadMessages(doc.id);
        list.add(Conversation(
          id: doc.id,
          title: data['title'] as String? ?? 'New Chat',
          messages: messages,
          createdAt: _toDateTime(data['createdAt']),
          updatedAt: _toDateTime(data['updatedAt']),
        ));
      }
      return list;
    });
  }

  // --- Clear all ------------------------------------------------------------

  Future<void> clearAll() async {
    final convs = await _convCol.get();
    for (final conv in convs.docs) {
      await deleteConversation(conv.id);
    }
    await _db.collection('users').doc(_userId).delete();
  }

  // --- Helpers --------------------------------------------------------------

  DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  Map<String, dynamic> _messageToMap(Message msg) => {
        'id': msg.id,
        'content': msg.content,
        'role': msg.role.name,
        'timestamp': Timestamp.fromDate(msg.timestamp),
        'status': msg.status.name,
        'isVoice': msg.isVoice,
      };

  Message _messageFromDoc(Map<String, dynamic> data) => Message(
        id: data['id'] as String,
        content: data['content'] as String,
        role: MessageRole.values.firstWhere(
          (e) => e.name == data['role'],
          orElse: () => MessageRole.user,
        ),
        timestamp: _toDateTime(data['timestamp']),
        status: MessageStatus.values.firstWhere(
          (e) => e.name == (data['status'] ?? 'sent'),
          orElse: () => MessageStatus.sent,
        ),
        isVoice: data['isVoice'] ?? false,
      );
}