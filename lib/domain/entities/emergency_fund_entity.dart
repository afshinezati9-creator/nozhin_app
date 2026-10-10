import 'package:equatable/equatable.dart';

/// صندوق اضطراری — یک رکورد تکی
class EmergencyFundEntity extends Equatable {
  final double target;
  final double current;

  const EmergencyFundEntity({
    this.target = 0,
    this.current = 0,
  });

  double get progress =>
      target <= 0 ? 0 : (current / target).clamp(0.0, 1.0);

  EmergencyFundEntity copyWith({double? target, double? current}) {
    return EmergencyFundEntity(
      target: target ?? this.target,
      current: current ?? this.current,
    );
  }

  @override
  List<Object?> get props => [target, current];
}
