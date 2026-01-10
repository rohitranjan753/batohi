import 'package:equatable/equatable.dart';
import '../../models/itinerary.dart';

enum ItineraryStatus { initial, loading, success, failure }

class ItineraryState extends Equatable {
  final ItineraryStatus status;
  final List<Itinerary> itineraries;
  final String? errorMessage;

  const ItineraryState({
    this.status = ItineraryStatus.initial,
    this.itineraries = const [],
    this.errorMessage,
  });

  ItineraryState copyWith({
    ItineraryStatus? status,
    List<Itinerary>? itineraries,
    String? errorMessage,
  }) {
    return ItineraryState(
      status: status ?? this.status,
      itineraries: itineraries ?? this.itineraries,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<int, List<Itinerary>> get itinerariesByDay {
    final Map<int, List<Itinerary>> dayMap = {};
    for (final item in itineraries) {
      dayMap[item.day] = [...(dayMap[item.day] ?? []), item];
    }
    // Sort each day's activities by time
    for (final day in dayMap.keys) {
      dayMap[day]!.sort((a, b) => a.time.compareTo(b.time));
    }
    return dayMap;
  }

  @override
  List<Object?> get props => [status, itineraries, errorMessage];
}
