import 'dart:async';

import 'package:flutter/widgets.dart';
import '../l10n/ext.dart';

String authErrorMessage(BuildContext context, Object error) {
  final l = context.l10n;
  if (error is TimeoutException) return l.errTimeout;
  final code = error.toString();
  if (code.contains('user-not-found') ||
      code.contains('wrong-password') ||
      code.contains('invalid-credential')) {
    return l.errBadCredentials;
  }
  if (code.contains('email-already-in-use')) return l.errEmailInUse;
  if (code.contains('weak-password')) return l.errWeakPassword;
  if (code.contains('invalid-email')) return l.errInvalidEmail;
  if (code.contains('network-request-failed')) return l.errNetwork;
  if (code.contains('too-many-requests')) return l.errTooMany;
  if (code.contains('user-disabled')) return l.errUserDisabled;
  return l.errUnexpected;
}

String dataErrorMessage(BuildContext context, Object error) {
  final l = context.l10n;
  final code = error.toString();
  if (code.contains('permission-denied')) return l.errPermission;
  if (code.contains('unavailable') ||
      code.contains('network') ||
      code.contains('failed')) {
    return l.errNetwork;
  }
  if (code.contains('not-found')) return l.errNotFound;
  return l.errGeneric;
}
