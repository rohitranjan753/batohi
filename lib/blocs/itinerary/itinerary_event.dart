import 'package:equatable/equatable.dart';
import '../../models/itinerary.dart';

abstract class ItineraryEvent extends Equatable {
  const ItineraryEvent();

  @override
  List<Object?> get props => [];
}

class LoadItineraries extends ItineraryEvent {
  final String tripId;

  const LoadItineraries(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

class AddItinerary extends ItineraryEvent {
  final String tripId;
  final int day;
  final DateTime time;
  final String title;
  final String? location;
  final String activityType;
  final String? notes;

  const AddItinerary({
    required this.tripId,
    required this.day,
    required this.time,
    required this.title,
    this.location,
    required this.activityType,
    this.notes,
  });

  @override
  List<Object?> get props => [tripId, day, time, title, location, activityType, notes];
}

class UpdateItinerary extends ItineraryEvent {
  final Itinerary itinerary;

  const UpdateItinerary(this.itinerary);

  @override
  List<Object?> get props => [itinerary];
}

class DeleteItinerary extends ItineraryEvent {
  final String itineraryId;

  const DeleteItinerary(this.itineraryId);

  @override
  List<Object?> get props => [itineraryId];
}
