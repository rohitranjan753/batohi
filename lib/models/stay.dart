import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Stay extends Equatable {
  final String id;
  final String tripId;
  final String userId;
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
  final DateTime createdAt;
  final DateTime updatedAt;

  const Stay({
    required this.id,
    required this.tripId,
    required this.userId,
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
    required this.createdAt,
    required this.updatedAt,
  });

  factory Stay.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Stay(
      id: doc.id,
      tripId: data['tripId'] ?? '',
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      address: data['address'],
      stayType: data['stayType'] ?? 'Hotel',
      checkIn: (data['checkIn'] as Timestamp).toDate(),
      checkOut: (data['checkOut'] as Timestamp).toDate(),
      costPerNight: data['costPerNight']?.toDouble(),
      currency: data['currency'],
      confirmationNumber: data['confirmationNumber'],
      contactNumber: data['contactNumber'],
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'userId': userId,
      'name': name,
      'address': address,
      'stayType': stayType,
      'checkIn': Timestamp.fromDate(checkIn),
      'checkOut': Timestamp.fromDate(checkOut),
      'costPerNight': costPerNight,
      'currency': currency,
      'confirmationNumber': confirmationNumber,
      'contactNumber': contactNumber,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Stay copyWith({
    String? id,
    String? tripId,
    String? userId,
    String? name,
    String? address,
    String? stayType,
    DateTime? checkIn,
    DateTime? checkOut,
    double? costPerNight,
    String? currency,
    String? confirmationNumber,
    String? contactNumber,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Stay(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      address: address ?? this.address,
      stayType: stayType ?? this.stayType,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      costPerNight: costPerNight ?? this.costPerNight,
      currency: currency ?? this.currency,
      confirmationNumber: confirmationNumber ?? this.confirmationNumber,
      contactNumber: contactNumber ?? this.contactNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get nights {
    return checkOut.difference(checkIn).inDays;
  }

  double get totalCost {
    if (costPerNight == null) return 0.0;
    return costPerNight! * nights;
  }

  @override
  List<Object?> get props => [
        id,
        tripId,
        userId,
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
        createdAt,
        updatedAt,
      ];

  static const List<String> stayTypes = [
    'Hotel',
    'Hostel',
    'Resort',
    'Airbnb',
    'Guesthouse',
    'Villa',
    'Apartment',
    'Camping',
    'Homestay',
    'Other',
  ];
}
