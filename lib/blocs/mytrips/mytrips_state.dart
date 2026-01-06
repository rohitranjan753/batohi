import 'package:equatable/equatable.dart';
import '../../models/trip.dart';

enum MyTripsStatus { initial, loading, success, failure }

class MyTripsState extends Equatable {
  final MyTripsStatus status;
  final List<Trip> trips;
  final String? errorMessage;

  const MyTripsState({
    this.status = MyTripsStatus.initial,
    this.trips = const [],
    this.errorMessage,
  });

  MyTripsState copyWith({
    MyTripsStatus? status,
    List<Trip>? trips,
    String? errorMessage,
  }) {
    return MyTripsState(
      status: status ?? this.status,
      trips: trips ?? this.trips,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, trips, errorMessage];
}