import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Trip extends Equatable {
  final String id;
  final String tripName;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final double budget;
  final String currency;
  final String notes;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isStarted;

  const Trip({
    required this.id,
    required this.tripName,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.budget,
    this.currency = 'INR', // Default to Indian Rupees
    this.notes = '',
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.isStarted = false, // Default to false (trip not started)
  });

  Trip copyWith({
    String? id,
    String? tripName,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
    String? currency,
    String? notes,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isStarted,
  }) {
    return Trip(
      id: id ?? this.id,
      tripName: tripName ?? this.tripName,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budget: budget ?? this.budget,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isStarted: isStarted ?? this.isStarted,
    );
  }

  // Convert Trip to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'tripName': tripName,
      'destination': destination,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'budget': budget,
      'currency': currency,
      'notes': notes,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isStarted': isStarted,
    };
  }

  // Create Trip from Firestore document
  factory Trip.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Trip(
      id: doc.id,
      tripName: data['tripName'] ?? '',
      destination: data['destination'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      budget: (data['budget'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'INR',
      notes: data['notes'] ?? '',
      userId: data['userId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isStarted: data['isStarted'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tripName,
        destination,
        startDate,
        endDate,
        budget,
        currency,
        notes,
        userId,
        createdAt,
        updatedAt,
        isStarted,
      ];
}