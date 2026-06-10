import 'package:cloud_firestore/cloud_firestore.dart';

class CampusEvent {
  final String id;
  final String title;
  final String cat; // Academic / Career / Sports / Social
  final String date;
  final String loc;
  final bool featured;
  final int tint; // ARGB int for the cover gradient

  const CampusEvent({
    required this.id,
    required this.title,
    required this.cat,
    required this.date,
    required this.loc,
    this.featured = false,
    this.tint = 0xFF1F3A5F,
  });

  factory CampusEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return CampusEvent(
      id: doc.id,
      title: d['title'] ?? '',
      cat: d['cat'] ?? 'Academic',
      date: d['date'] ?? '',
      loc: d['loc'] ?? '',
      featured: d['featured'] ?? false,
      tint: d['tint'] is int
          ? d['tint']
          : int.tryParse('${d['tint']}') ?? 0xFF1F3A5F,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'cat': cat,
        'date': date,
        'loc': loc,
        'featured': featured,
        'tint': tint,
      };
}
