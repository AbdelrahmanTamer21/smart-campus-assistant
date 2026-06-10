import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

/// A dated timetable occurrence expanded from a course's weekly sessions.
/// Staff edits write overrides here (room / status).
class ClassOccurrence {
  final String id;
  final String courseId;
  final String code;
  final String title;
  final String profName;
  final DateTime date;
  final String start;
  final String end;
  final String room;
  final ClassStatus status;
  final String? originalRoom;

  const ClassOccurrence({
    required this.id,
    required this.courseId,
    required this.code,
    required this.title,
    required this.profName,
    required this.date,
    required this.start,
    required this.end,
    required this.room,
    this.status = ClassStatus.confirmed,
    this.originalRoom,
  });

  factory ClassOccurrence.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return ClassOccurrence(
      id: doc.id,
      courseId: d['courseId'] ?? '',
      code: d['code'] ?? '',
      title: d['title'] ?? '',
      profName: d['profName'] ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      start: d['start'] ?? '',
      end: d['end'] ?? '',
      room: d['room'] ?? '',
      status: ClassStatusX.fromId(d['status']),
      originalRoom: d['originalRoom'],
    );
  }

  Map<String, dynamic> toMap() => {
        'courseId': courseId,
        'code': code,
        'title': title,
        'profName': profName,
        'date': Timestamp.fromDate(date),
        'start': start,
        'end': end,
        'room': room,
        'status': status.id,
        'originalRoom': originalRoom,
      };

  String get timeLabel => '$start – $end';
}
