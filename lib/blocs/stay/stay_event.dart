import 'package:equatable/equatable.dart';
import '../../models/stay.dart';

abstract class StayEvent extends Equatable {
  const StayEvent();

  @override
  List<Object?> get props => [];
}

class LoadStays extends StayEvent {
  final String tripId;

  const LoadStays(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

class AddStay extends StayEvent {
  final String tripId;
  final String name;
  final String? address;
  final String stayType;
  final DateTime checkIn;
  final DateTime checkOut;
  final double? costPerNight;
  final String? currency;
  final String? confirmationNumber;
  final String? contactNumber;
  final String? notes;

  const AddStay({
    required this.tripId,
    required this.name,
    this.address,
    required this.stayType,
    required this.checkIn,
    required this.checkOut,
    this.costPerNight,
    this.currency,
    this.confirmationNumber,
    this.contactNumber,
    this.notes,
  });

  @override
  List<Object?> get props => [
        tripId,
        name,
        address,
        stayType,
        checkIn,
        checkOut,
        costPerNight,
        currency,
        confirmationNumber,
        contactNumber,
        notes,
      ];
}

class UpdateStay extends StayEvent {
  final Stay stay;

  const UpdateStay(this.stay);

  @override
  List<Object?> get props => [stay];
}

class DeleteStay extends StayEvent {
  final String stayId;

  const DeleteStay(this.stayId);

  @override
  List<Object?> get props => [stayId];
}
