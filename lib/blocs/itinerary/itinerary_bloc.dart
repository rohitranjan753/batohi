import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../models/itinerary.dart';
import 'itinerary_event.dart';
import 'itinerary_state.dart';

class ItineraryBloc extends Bloc<ItineraryEvent, ItineraryState> {
  ItineraryBloc() : super(const ItineraryState()) {
    on<LoadItineraries>(_onLoadItineraries);
    on<AddItinerary>(_onAddItinerary);
    on<UpdateItinerary>(_onUpdateItinerary);
    on<DeleteItinerary>(_onDeleteItinerary);
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  Future<void> _onLoadItineraries(
    LoadItineraries event,
    Emitter<ItineraryState> emit,
  ) async {
    if (_userId.isEmpty) return;

    emit(state.copyWith(status: ItineraryStatus.loading));

    try {
      final querySnapshot = await _firestore
          .collection('itineraries')
          .where('userId', isEqualTo: _userId)
          .where('tripId', isEqualTo: event.tripId)
          .orderBy('day')
          .orderBy('time')
          .get();

      final itineraries = querySnapshot.docs
          .map((doc) => Itinerary.fromDocument(doc))
          .toList();

      emit(state.copyWith(
        status: ItineraryStatus.success,
        itineraries: itineraries,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ItineraryStatus.failure,
        errorMessage: 'Failed to load itineraries: ${e.toString()}',
      ));
    }
  }

  Future<void> _onAddItinerary(
    AddItinerary event,
    Emitter<ItineraryState> emit,
  ) async {
    if (_userId.isEmpty) {
      emit(state.copyWith(
        status: ItineraryStatus.failure,
        errorMessage: 'User not authenticated',
      ));
      return;
    }

    emit(state.copyWith(status: ItineraryStatus.loading));

    try {
      final now = DateTime.now();
      final itineraryData = {
        'tripId': event.tripId,
        'userId': _userId,
        'day': event.day,
        'time': Timestamp.fromDate(event.time),
        'title': event.title,
        'location': event.location,
        'activityType': event.activityType,
        'notes': event.notes,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      final docRef = await _firestore.collection('itineraries').add(itineraryData);

      final newItinerary = Itinerary(
        id: docRef.id,
        tripId: event.tripId,
        userId: _userId,
        day: event.day,
        time: event.time,
        title: event.title,
        location: event.location,
        activityType: event.activityType,
        notes: event.notes,
        createdAt: now,
        updatedAt: now,
      );

      final updatedItineraries = [...state.itineraries, newItinerary];
      updatedItineraries.sort((a, b) {
        final dayCompare = a.day.compareTo(b.day);
        if (dayCompare != 0) return dayCompare;
        return a.time.compareTo(b.time);
      });

      emit(state.copyWith(
        status: ItineraryStatus.success,
        itineraries: updatedItineraries,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ItineraryStatus.failure,
        errorMessage: 'Failed to add itinerary: ${e.toString()}',
      ));
    }
  }

  Future<void> _onUpdateItinerary(
    UpdateItinerary event,
    Emitter<ItineraryState> emit,
  ) async {
    if (_userId.isEmpty) return;

    emit(state.copyWith(status: ItineraryStatus.loading));

    try {
      final updatedItinerary = event.itinerary.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('itineraries')
          .doc(updatedItinerary.id)
          .update(updatedItinerary.toMap());

      final updatedItineraries = state.itineraries.map((item) {
        return item.id == updatedItinerary.id ? updatedItinerary : item;
      }).toList();

      emit(state.copyWith(
        status: ItineraryStatus.success,
        itineraries: updatedItineraries,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ItineraryStatus.failure,
        errorMessage: 'Failed to update itinerary: ${e.toString()}',
      ));
    }
  }

  Future<void> _onDeleteItinerary(
    DeleteItinerary event,
    Emitter<ItineraryState> emit,
  ) async {
    if (_userId.isEmpty) return;

    emit(state.copyWith(status: ItineraryStatus.loading));

    try {
      await _firestore.collection('itineraries').doc(event.itineraryId).delete();

      final updatedItineraries = state.itineraries
          .where((item) => item.id != event.itineraryId)
          .toList();

      emit(state.copyWith(
        status: ItineraryStatus.success,
        itineraries: updatedItineraries,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ItineraryStatus.failure,
        errorMessage: 'Failed to delete itinerary: ${e.toString()}',
      ));
    }
  }
}
