import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoURL;

  const User({
    required this.id,
    this.email,
    this.displayName,
    this.photoURL,
  });

  static const empty = User(id: '');

  bool get isEmpty => this == User.empty;

  bool get isNotEmpty => this != User.empty;

  @override
  List<Object?> get props => [id, email, displayName, photoURL];
}