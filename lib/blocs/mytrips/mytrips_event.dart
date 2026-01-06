import 'package:equatable/equatable.dart';
import '../../models/trip.dart';

abstract class MyTripsEvent extends Equatable {
  const MyTripsEvent();

  @override
  List<Object?> get props => [];
}

class LoadTrips extends MyTripsEvent {
  const LoadTrips();
}

class AddTrip extends MyTripsEvent {
  final String tripName;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final double budget;
  final String currency;
  final String notes;
  final bool isStarted;

  const AddTrip({
    required this.tripName,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.budget,
    this.currency = 'INR',
    this.notes = '',
    this.isStarted = false,
  });

  @override
  List<Object?> get props => [
        tripName,
        destination,
        startDate,
        endDate,
        budget,
        currency,
        notes,
        isStarted,
      ];
}

class UpdateTrip extends MyTripsEvent {
  final Trip trip;

  const UpdateTrip(this.trip);

  @override
  List<Object?> get props => [trip];
}

class DeleteTrip extends MyTripsEvent {
  final String tripId;

  const DeleteTrip(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

class ToggleTripStatus extends MyTripsEvent {
  final String tripId;
  final bool isStarted;

  const ToggleTripStatus({
    required this.tripId,
    required this.isStarted,
  });

  @override
  List<Object?> get props => [tripId, isStarted];
}