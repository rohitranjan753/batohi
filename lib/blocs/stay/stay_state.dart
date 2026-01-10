import 'package:equatable/equatable.dart';
import '../../models/stay.dart';

enum StayStatus { initial, loading, success, failure }

class StayState extends Equatable {
  final StayStatus status;
  final List<Stay> stays;
  final String? errorMessage;

  const StayState({
    this.status = StayStatus.initial,
    this.stays = const [],
    this.errorMessage,
  });

  StayState copyWith({
    StayStatus? status,
    List<Stay>? stays,
    String? errorMessage,
  }) {
    return StayState(
      status: status ?? this.status,
      stays: stays ?? this.stays,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  double get totalStayCost {
    return stays.fold(0.0, (sum, stay) => sum + stay.totalCost);
  }

  int get totalNights {
    return stays.fold(0, (sum, stay) => sum + stay.nights);
  }

  @override
  List<Object?> get props => [status, stays, errorMessage];
}
