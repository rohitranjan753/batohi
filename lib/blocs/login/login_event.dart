import 'package:equatable/equatable.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object> get props => [];
}

class LoginGooglePressed extends LoginEvent {
  const LoginGooglePressed();
}