import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';

class ChatRepo {
  final FirebaseFirestore _db;
  ChatRepo({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('chats').doc(uid).collection('messages');

  Stream<List<ChatMessage>> watch(String uid) => _col(uid)
      .orderBy('time')
      .snapshots()
      .map((s) => s.docs.map(ChatMessage.fromDoc).toList());

  Future<void> add(String uid, ChatMessage m) => _col(uid).add(m.toMap());
}
