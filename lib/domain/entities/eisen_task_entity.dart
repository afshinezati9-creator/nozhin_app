import 'package:equatable/equatable.dart';

enum EisenQuadrant { q1, q2, q3, q4 }

extension EisenQuadrantX on EisenQuadrant {
  String get label {
    switch (this) {
      case EisenQuadrant.q1:
        return 'فوری و مهم';
      case EisenQuadrant.q2:
        return 'مهم، نه فوری';
      case EisenQuadrant.q3:
        return 'فوری، نه مهم';
      case EisenQuadrant.q4:
        return 'نه فوری، نه مهم';
    }
  }
}

class EisenTaskEntity extends Equatable {
  final String id;
  final String text;
  final EisenQuadrant quadrant;
  final bool done;
  final DateTime createdAt;

  const EisenTaskEntity({
    required this.id,
    required this.text,
    required this.quadrant,
    this.done = false,
    required this.createdAt,
  });

  EisenTaskEntity copyWith({
    String? id,
    String? text,
    EisenQuadrant? quadrant,
    bool? done,
    DateTime? createdAt,
  }) {
    return EisenTaskEntity(
      id: id ?? this.id,
      text: text ?? this.text,
      quadrant: quadrant ?? this.quadrant,
      done: done ?? this.done,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, text, quadrant, done, createdAt];
}
