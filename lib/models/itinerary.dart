import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Itinerary extends Equatable {
  final String id;
  final String tripId;
  final String userId;
  final int day;
  final DateTime time;
  final String title;
  final String? location;
  final String activityType;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Itinerary({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.day,
    required this.time,
    required this.title,
    this.location,
    required this.activityType,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Itinerary.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Itinerary(
      id: doc.id,
      tripId: data['tripId'] ?? '',
      userId: data['userId'] ?? '',
      day: data['day'] ?? 1,
      time: (data['time'] as Timestamp).toDate(),
      title: data['title'] ?? '',
      location: data['location'],
      activityType: data['activityType'] ?? 'Other',
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'userId': userId,
      'day': day,
      'time': Timestamp.fromDate(time),
      'title': title,
      'location': location,
      'activityType': activityType,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Itinerary copyWith({
    String? id,
    String? tripId,
    String? userId,
    int? day,
    DateTime? time,
    String? title,
    String? location,
    String? activityType,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Itinerary(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      userId: userId ?? this.userId,
      day: day ?? this.day,
      time: time ?? this.time,
      title: title ?? this.title,
      location: location ?? this.location,
      activityType: activityType ?? this.activityType,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tripId,
        userId,
        day,
        time,
        title,
        location,
        activityType,
        notes,
        createdAt,
        updatedAt,
      ];

  static const List<String> activityTypes = [
    'Sightseeing',
    'Adventure',
    'Relaxation',
    'Food & Dining',
    'Shopping',
    'Transportation',
    'Cultural',
    'Entertainment',
    'Nature',
    'Photography',
    'Other',
  ];
}
