import 'package:flutter/material.dart';

/// Global navigator key shared by routing and app-level snackbars.
class AppNavKeys {
  const AppNavKeys._();

  static final GlobalKey<NavigatorState> appNavKey =
      GlobalKey<NavigatorState>();
}
