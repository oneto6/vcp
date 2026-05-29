import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

typedef OnEntry =
    FutureOr<OnEnterResult> Function(
      BuildContext,
      GoRouterState,
      GoRouterState,
      GoRouter,
    )?;

abstract class RouterState {
  final GoRouter config;
  RouterState(this.config);
}

class RouterInital extends RouterState {
  RouterInital(super.config);
}

class RouterLogin extends RouterState {
  RouterLogin(super.config);
}
