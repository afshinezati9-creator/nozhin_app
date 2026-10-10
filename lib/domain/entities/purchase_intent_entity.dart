/// قصد خرید — لیست ساده کالا (جدا از هدف‌گذاری پس‌انداز)
enum PurchaseIntentStatus {
  pending,
  bought,
  couldNot,
}

class PurchaseIntentEntity {
  final String id;
  final String title;
  final double? amount; // اختیاری
  final DateTime plannedDate; // تاریخ هدف خرید
  final PurchaseIntentStatus status;
  final bool archived;
  final DateTime createdAt;
  final String note;
  final DateTime? resolvedAt;
  /// ۱=بالا … ۴=پایین (اختیاری)
  final int priority;

  const PurchaseIntentEntity({
    required this.id,
    required this.title,
    this.amount,
    required this.plannedDate,
    this.status = PurchaseIntentStatus.pending,
    this.archived = false,
    this.note = '',
    required this.createdAt,
    this.resolvedAt,
    this.priority = 2,
  });

  PurchaseIntentEntity copyWith({
    String? title,
    double? amount,
    bool clearAmount = false,
    DateTime? plannedDate,
    PurchaseIntentStatus? status,
    bool? archived,
    String? note,
    DateTime? resolvedAt,
    int? priority,
  }) {
    return PurchaseIntentEntity(
      id: id,
      title: title ?? this.title,
      amount: clearAmount ? null : (amount ?? this.amount),
      plannedDate: plannedDate ?? this.plannedDate,
      status: status ?? this.status,
      archived: archived ?? this.archived,
      note: note ?? this.note,
      createdAt: createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      priority: (priority ?? this.priority).clamp(1, 4),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'plannedDate': plannedDate.toIso8601String(),
        'status': status.name,
        'archived': archived,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
        'priority': priority,
      };

  factory PurchaseIntentEntity.fromMap(Map<String, dynamic> m) {
    return PurchaseIntentEntity(
      id: m['id'] as String,
      title: (m['title'] as String?) ?? '',
      amount: (m['amount'] as num?)?.toDouble(),
      plannedDate:
          DateTime.tryParse('${m['plannedDate']}') ?? DateTime.now(),
      status: PurchaseIntentStatus.values.firstWhere(
        (e) => e.name == m['status'],
        orElse: () => PurchaseIntentStatus.pending,
      ),
      archived: m['archived'] == true,
      note: (m['note'] as String?) ?? '',
      createdAt: DateTime.tryParse('${m['createdAt']}') ?? DateTime.now(),
      priority: (m['priority'] as int?)?.clamp(1, 4) ?? 2,
      resolvedAt: m['resolvedAt'] != null
          ? DateTime.tryParse('${m['resolvedAt']}')
          : null,
    );
  }
}

enum PurchaseTimeTab { today, week, month, year }

class PurchaseTimeFilter {
  /// هفته شمسی: شنبه تا جمعه
  static int daysSinceSaturday(DateTime d) {
    switch (d.weekday) {
      case DateTime.saturday:
        return 0;
      case DateTime.sunday:
        return 1;
      case DateTime.monday:
        return 2;
      case DateTime.tuesday:
        return 3;
      case DateTime.wednesday:
        return 4;
      case DateTime.thursday:
        return 5;
      case DateTime.friday:
        return 6;
      default:
        return 0;
    }
  }

  static bool matches(DateTime planned, PurchaseTimeTab tab) {
    final now = DateTime.now();
    final p = DateTime(planned.year, planned.month, planned.day);
    final n = DateTime(now.year, now.month, now.day);

    switch (tab) {
      case PurchaseTimeTab.today:
        return p == n;
      case PurchaseTimeTab.week:
        final start = n.subtract(Duration(days: daysSinceSaturday(n)));
        final end = start.add(const Duration(days: 6));
        return !p.isBefore(start) && !p.isAfter(end);
      case PurchaseTimeTab.month:
        return p.year == n.year && p.month == n.month;
      case PurchaseTimeTab.year:
        return p.year == n.year;
    }
  }

  static bool isOverdue(DateTime planned, PurchaseIntentStatus status) {
    if (status != PurchaseIntentStatus.pending) return false;
    final p = DateTime(planned.year, planned.month, planned.day);
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    return p.isBefore(today);
  }
}
