import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../models/trip.dart';
import 'mytrips_event.dart';
import 'mytrips_state.dart';

class MyTripsBloc extends Bloc<MyTripsEvent, MyTripsState> {
  MyTripsBloc() : super(const MyTripsState()) {
    on<LoadTrips>(_onLoadTrips);
    on<AddTrip>(_onAddTrip);
    on<UpdateTrip>(_onUpdateTrip);
    on<DeleteTrip>(_onDeleteTrip);
    on<ToggleTripStatus>(_onToggleTripStatus);
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  Future<void> _onLoadTrips(
    LoadTrips event,
    Emitter<MyTripsState> emit,
  ) async {
    if (_userId.isEmpty) return;

    emit(state.copyWith(status: MyTripsStatus.loading));

    try {
      final querySnapshot = await _firestore
          .collection('trips')
          .where('userId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .get();

      final trips = querySnapshot.docs
          .map((doc) => Trip.fromDocument(doc))
          .toList();

      emit(state.copyWith(
        status: MyTripsStatus.success,
        trips: trips,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MyTripsStatus.failure,
        errorMessage: 'Failed to load trips: ${e.toString()}',
      ));
    }
  }

  Future<void> _onAddTrip(
    AddTrip event,
    Emitter<MyTripsState> emit,
  ) async {
    if (_userId.isEmpty) {
      emit(state.copyWith(
        status: MyTripsStatus.failure,
        errorMessage: 'User not authenticated',
      ));
      return;
    }

    emit(state.copyWith(status: MyTripsStatus.loading));

    try {
      final now = DateTime.now();
      final tripData = {
        'tripName': event.tripName,
        'destination': event.destination,
        'startDate': Timestamp.fromDate(event.startDate),
        'endDate': Timestamp.fromDate(event.endDate),
        'budget': event.budget,
        'currency': event.currency,
        'notes': event.notes,
        'userId': _userId,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'isStarted': event.isStarted,
      };

      final docRef = await _firestore.collection('trips').add(tripData);
      
      final newTrip = Trip(
        id: docRef.id,
        tripName: event.tripName,
        destination: event.destination,
        startDate: event.startDate,
        endDate: event.endDate,
        budget: event.budget,
        currency: event.currency,
        notes: event.notes,
        userId: _userId,
        createdAt: now,
        updatedAt: now,
        isStarted: event.isStarted,
      );

      final updatedTrips = [newTrip, ...state.trips];

      emit(state.copyWith(
        status: MyTripsStatus.success,
        trips: updatedTrips,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MyTripsStatus.failure,
        errorMessage: 'Failed to add trip: ${e.toString()}',
      ));
    }
  }

  Future<void> _onUpdateTrip(
    UpdateTrip event,
    Emitter<MyTripsState> emit,
  ) async {
    if (_userId.isEmpty) return;

    emit(state.copyWith(status: MyTripsStatus.loading));

    try {
      final updatedTrip = event.trip.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('trips')
          .doc(updatedTrip.id)
          .update(updatedTrip.toMap());

      final updatedTrips = state.trips.map((trip) {
        return trip.id == updatedTrip.id ? updatedTrip : trip;
      }).toList();

      emit(state.copyWith(
        status: MyTripsStatus.success,
        trips: updatedTrips,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MyTripsStatus.failure,
        errorMessage: 'Failed to update trip: ${e.toString()}',
      ));
    }
  }

  Future<void> _onDeleteTrip(
    DeleteTrip event,
    Emitter<MyTripsState> emit,
  ) async {
    if (_userId.isEmpty) return;

    emit(state.copyWith(status: MyTripsStatus.loading));

    try {
      await _firestore.collection('trips').doc(event.tripId).delete();

      final updatedTrips = state.trips
          .where((trip) => trip.id != event.tripId)
          .toList();

      emit(state.copyWith(
        status: MyTripsStatus.success,
        trips: updatedTrips,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MyTripsStatus.failure,
        errorMessage: 'Failed to delete trip: ${e.toString()}',
      ));
    }
  }

  Future<void> _onToggleTripStatus(
    ToggleTripStatus event,
    Emitter<MyTripsState> emit,
  ) async {
    if (_userId.isEmpty) return;

    emit(state.copyWith(status: MyTripsStatus.loading));

    try {
      final now = DateTime.now();
      
      // Update the trip status in Firestore
      await _firestore
          .collection('trips')
          .doc(event.tripId)
          .update({
        'isStarted': event.isStarted,
        'updatedAt': Timestamp.fromDate(now),
      });

      // Update the local state
      final updatedTrips = state.trips.map((trip) {
        if (trip.id == event.tripId) {
          return trip.copyWith(
            isStarted: event.isStarted,
            updatedAt: now,
          );
        }
        return trip;
      }).toList();

      emit(state.copyWith(
        status: MyTripsStatus.success,
        trips: updatedTrips,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MyTripsStatus.failure,
        errorMessage: 'Failed to update trip status: ${e.toString()}',
      ));
    }
  }
}