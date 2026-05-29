abstract class AuthEvent {}

class AuthSetJWT extends AuthEvent {
  final String jwt;

  AuthSetJWT(this.jwt);
}

class AuthLogout extends AuthEvent {}

class AuthFailed extends AuthEvent {}
