import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../models/stay.dart';
import 'stay_event.dart';
import 'stay_state.dart';

class StayBloc extends Bloc<StayEvent, StayState> {
  StayBloc() : super(const StayState()) {
    on<LoadStays>(_onLoadStays);
    on<AddStay>(_onAddStay);
    on<UpdateStay>(_onUpdateStay);
    on<DeleteStay>(_onDeleteStay);
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  Future<void> _onLoadStays(
    LoadStays event,
    Emitter<StayState> emit,
  ) async {
    if (_userId.isEmpty) return;

    emit(state.copyWith(status: StayStatus.loading));

    try {
      final querySnapshot = await _firestore
          .collection('stays')
          .where('userId', isEqualTo: _userId)
          .where('tripId', isEqualTo: event.tripId)
          .orderBy('checkIn')
          .get();

      final stays = querySnapshot.docs
          .map((doc) => Stay.fromDocument(doc))
          .toList();

      emit(state.copyWith(
        status: StayStatus.success,
        stays: stays,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: StayStatus.failure,
        errorMessage: 'Failed to load stays: ${e.toString()}',
      ));
    }
  }

  Future<void> _onAddStay(
    AddStay event,
    Emitter<StayState> emit,
  ) async {
    if (_userId.isEmpty) {
      emit(state.copyWith(
        status: StayStatus.failure,
        errorMessage: 'User not authenticated',
      ));
      return;
    }

    emit(state.copyWith(status: StayStatus.loading));

    try {
      final now = DateTime.now();
      final stayData = {
        'tripId': event.tripId,
        'userId': _userId,
        'name': event.name,
        'address': event.address,
        'stayType': event.stayType,
        'checkIn': Timestamp.fromDate(event.checkIn),
        'checkOut': Timestamp.fromDate(event.checkOut),
        'costPerNight': event.costPerNight,
        'currency': event.currency,
        'confirmationNumber': event.confirmationNumber,
        'contactNumber': event.contactNumber,
        'notes': event.notes,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      final docRef = await _firestore.collection('stays').add(stayData);

      final newStay = Stay(
        id: docRef.id,
        tripId: event.tripId,
        userId: _userId,
        name: event.name,
        address: event.address,
        stayType: event.stayType,
        checkIn: event.checkIn,
        checkOut: event.checkOut,
        costPerNight: event.costPerNight,
        currency: event.currency,
        confirmationNumber: event.confirmationNumber,
        contactNumber: event.contactNumber,
        notes: event.notes,
        createdAt: now,
        updatedAt: now,
      );

      final updatedStays = [...state.stays, newStay];
      updatedStays.sort((a, b) => a.checkIn.compareTo(b.checkIn));

      emit(state.copyWith(
        status: StayStatus.success,
        stays: updatedStays,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: StayStatus.failure,
        errorMessage: 'Failed to add stay: ${e.toString()}',
      ));
    }
  }

  Future<void> _onUpdateStay(
    UpdateStay event,
    Emitter<StayState> emit,
  ) async {
    if (_userId.isEmpty) return;

    emit(state.copyWith(status: StayStatus.loading));

    try {
      final updatedStay = event.stay.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('stays')
          .doc(updatedStay.id)
          .update(updatedStay.toMap());

      final updatedStays = state.stays.map((stay) {
        return stay.id == updatedStay.id ? updatedStay : stay;
      }).toList();

      emit(state.copyWith(
        status: StayStatus.success,
        stays: updatedStays,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: StayStatus.failure,
        errorMessage: 'Failed to update stay: ${e.toString()}',
      ));
    }
  }

  Future<void> _onDeleteStay(
    DeleteStay event,
    Emitter<StayState> emit,
  ) async {
    if (_userId.isEmpty) return;

    emit(state.copyWith(status: StayStatus.loading));

    try {
      await _firestore.collection('stays').doc(event.stayId).delete();

      final updatedStays = state.stays
          .where((stay) => stay.id != event.stayId)
          .toList();

      emit(state.copyWith(
        status: StayStatus.success,
        stays: updatedStays,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: StayStatus.failure,
        errorMessage: 'Failed to delete stay: ${e.toString()}',
      ));
    }
  }
}
