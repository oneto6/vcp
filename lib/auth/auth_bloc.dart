import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vcp/auth/auth_event.dart';
import 'package:vcp/auth/auth_state.dart';
import 'package:vcp/authorization.dart';

void init(Function(AuthEvent) add) async {
  final res = await () async {
    final err = AuthFailed();

    // SharedPreferences.setMockInitialValues({
    //   "authorization":
    //       "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWUsImV4cCI6MTc5NTkxMDQwMCwiaWF0IjoxNTE2MjM5MDIyfQ.K8kSYPpvsbhZwNDdFEt20nqlT2n583h_JKmKTZQ_kgo",
    // });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final authString = prefs.getString("authorization");
    print(authString);
    if (authString == null) return err;

    ApiService.initialize(authString);
    final jwtMap = JwtDecoder.decode(authString);
    print(jwtMap);
    final expiry = jwtMap['exp'];
    if (expiry is! int) return err;

    final dateTime = DateTime.tryParse(expiry.toString());
    print("dateTime: ${dateTime}");
    if (dateTime == null || dateTime.isBefore(DateTime.now())) return err;
    print(authString);
    return AuthSetJWT(authString);
    // jwtMap[]
  }();

  print(res);
  add(res);
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthUnknown()) {
    init(add);
    on<AuthSetJWT>((event, emit) {
      ApiService.initialize(event.jwt);
      emit(AuthLogin());
    });

    on<AuthLogout>((event, emit) {
      emit(AuthUnauthorized());
    });

    on<AuthFailed>((event, emit) {
      emit(AuthUnauthorized());
    });
  }
}
