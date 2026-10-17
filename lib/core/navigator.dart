import 'package:flutter/material.dart';

/// App-wide navigator, so out-of-tree events (a tapped OS push) can route the
/// user to the referenced listing/post without holding a [BuildContext].
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
