import 'package:cloud_firestore/cloud_firestore.dart';

/// In-app notification (F10). Mirrors a pushed FCM message; drives the bell
/// badge + Notifications inbox; deep-links via [route].
class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; // class | deadline | announcement
  final String? route;
  final bool read;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.type = 'announcement',
    this.route,
    this.read = false,
    this.createdAt,
  });

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppNotification(
      id: doc.id,
      title: d['title'] ?? '',
      body: d['body'] ?? '',
      type: d['type'] ?? 'announcement',
      route: d['route'],
      read: d['read'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'type': type,
        'route': route,
        'read': read,
        'createdAt': FieldValue.serverTimestamp(),
      };

  String get timeAgo {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }
}
