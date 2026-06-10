import 'package:cloud_firestore/cloud_firestore.dart';

class StatItem {
  final String value;
  final String label;
  final String? trend;
  final bool trendUp;
  const StatItem({
    required this.value,
    required this.label,
    this.trend,
    this.trendUp = true,
  });
  factory StatItem.fromMap(Map<String, dynamic> m) => StatItem(
        value: m['value'] ?? '',
        label: m['label'] ?? '',
        trend: m['trend'],
        trendUp: m['trendUp'] ?? true,
      );
}

class AdminStats {
  final List<StatItem> stats;
  final List<int> engagementWeek;
  final List<int> engagementMonth;
  const AdminStats({
    this.stats = const [],
    this.engagementWeek = const [],
    this.engagementMonth = const [],
  });

  factory AdminStats.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AdminStats(
      stats: (d['stats'] as List?)
              ?.map((e) => StatItem.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      engagementWeek: List<int>.from(d['engagementWeek'] ?? const []),
      engagementMonth: List<int>.from(d['engagementMonth'] ?? const []),
    );
  }
}
