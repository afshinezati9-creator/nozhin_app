import 'package:equatable/equatable.dart';

/// موجودیت یادداشت – لایه دامنه (بدون وابستگی به دیتابیس)
class NoteEntity extends Equatable {
  final String id;
  final String title;
  final String body; // HTML یا متن غنی
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pinned;
  final String color; // blue, green, yellow, red, purple, pink, ...
  final String direction; // rtl | ltr
  final List<String> tags;

  const NoteEntity({
    required this.id,
    required this.title,
    required this.body,
    this.category = 'عمومی',
    required this.createdAt,
    required this.updatedAt,
    this.pinned = false,
    this.color = 'blue',
    this.direction = 'rtl',
    this.tags = const [],
  });

  NoteEntity copyWith({
    String? id,
    String? title,
    String? body,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? pinned,
    String? color,
    String? direction,
    List<String>? tags,
  }) {
    return NoteEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pinned: pinned ?? this.pinned,
      color: color ?? this.color,
      direction: direction ?? this.direction,
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props => [
        id, title, body, category, createdAt, updatedAt,
        pinned, color, direction, tags,
      ];
}
