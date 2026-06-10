import 'package:cloud_firestore/cloud_firestore.dart';

/// One AI-chat turn. A "rich" message carries a room card payload.
class ChatMessage {
  final String id;
  final String from; // 'ai' | 'user'
  final String text;
  final String? rich; // 'room' when a RoomCard should render
  final String? roomTitle;
  final String? roomSub;
  final DateTime? time;

  const ChatMessage({
    this.id = '',
    required this.from,
    required this.text,
    this.rich,
    this.roomTitle,
    this.roomSub,
    this.time,
  });

  bool get isAI => from == 'ai';

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return ChatMessage(
      id: doc.id,
      from: d['from'] ?? 'ai',
      text: d['text'] ?? '',
      rich: d['rich'],
      roomTitle: d['roomTitle'],
      roomSub: d['roomSub'],
      time: (d['time'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'from': from,
        'text': text,
        'rich': rich,
        'roomTitle': roomTitle,
        'roomSub': roomSub,
        'time': time != null ? Timestamp.fromDate(time!) : FieldValue.serverTimestamp(),
      };

  String get timeLabel {
    final t = time;
    if (t == null) return '';
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
  }
}
