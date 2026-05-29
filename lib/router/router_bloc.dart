import 'dart:async' show FutureOr, StreamSubscription;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vcp/auth/auth.dart';
import 'package:vcp/main.dart';

FutureOr<OnEnterResult> onEntry(
  BuildContext _,
  GoRouterState _,
  GoRouterState _,
  GoRouter _,
) async {
  return Allow();
}

// GoRoute(path: "/", builder: (context, state) => const MyHomePage()),
//   GoRoute( path: "/auth/google", builder: (context, state) => const AuthHandleGoogle(),),
//   GoRoute(
//     path: "/getting-started",
//     builder: (context, state) => const GettingStarted(),
//   ),
//   GoRoute(path: "/login", builder: (context, state) => const Login()),

final unknownConfig = GoRouter(
  routes: [
    GoRoute(
      path: "/",
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text("unknownConfig")),
        body: Center(
          child: SizedBox.square(child: CircularProgressIndicator()),
        ),
      ),
    ),
  ],
);

final unauthorizedConfig = GoRouter(
  initialLocation: "/getting-started",
  routes: [
    GoRoute(
      path: "/getting-started",
      builder: (context, state) => const GettingStarted(),
    ),
    GoRoute(path: "/login", builder: (context, state) => const Login()),
  ],
);

GoRouter go(AuthState state) {
  return switch (state) {
    AuthLogin _ => GoRouter(
      routes: [
        GoRoute(path: "/", builder: (context, state) => const MyHomePage()),

        GoRoute(
          path: "/auth/google",
          builder: (context, state) => const AuthHandleGoogle(),
        ),
      ],
    ),
    AuthUnknown _ => unknownConfig,
    _ => unauthorizedConfig,
  };
}

class RouterCubit extends Cubit<GoRouter> {
  final AuthBloc authBloc;
  late StreamSubscription<AuthState> authBlocSub;

  RouterCubit(this.authBloc) : super(unknownConfig) {
    emit(go(authBloc.state));
    authBlocSub = authBloc.stream.listen(onData);
  }

  void onData(AuthState state) {
    emit(go(state));
  }

  @override
  Future<void> close() {
    authBlocSub.cancel;
    return super.close();
  }
}
