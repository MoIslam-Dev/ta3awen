import 'dart:async';

import 'package:flutter/material.dart';
import '../l10n/ext.dart';

/// Maps any auth/social-sign-in failure to a short, honest, user-facing
/// message. Social providers report walled flows (cancel, SHA-1 mismatch,
/// disabled provider) as differently-shaped exceptions, so we normalize the
/// string to lowercase and match recognizable fragments.
String authErrorMessage(BuildContext context, Object error) {
  final l = context.l10n;
  if (error is TimeoutException) return l.errTimeout;
  final msg = error.toString().toLowerCase();

  if (msg.contains('aborted-by-user') ||
      msg.contains('cancel') ||
      msg.contains('popup-closed-by-user') ||
      (msg.contains('google') && msg.contains('interrupted'))) {
    return l.errAuthCanceled;
  }

  if (msg.contains('operation-not-allowed') ||
      msg.contains('admin-restricted-operation')) {
    return l.errProviderDisabled;
  }

  if (msg.contains('provider-config') ||
      msg.contains('client_configuration') ||
      msg.contains('invalid-client') ||
      msg.contains('invalid_client') ||
      msg.contains('unauthorized-client') ||
      msg.contains('12500') ||
      msg.contains('10016')) {
    return l.errProviderConfig;
  }

  if (msg.contains('user-not-found') ||
      msg.contains('wrong-password') ||
      msg.contains('invalid-credential')) {
    return l.errBadCredentials;
  }
  if (msg.contains('email-already-in-use')) return l.errEmailInUse;
  if (msg.contains('weak-password')) return l.errWeakPassword;
  if (msg.contains('invalid-email')) return l.errInvalidEmail;
  if (msg.contains('network-request-failed')) return l.errNetwork;
  if (msg.contains('too-many-requests')) return l.errTooMany;
  if (msg.contains('user-disabled')) return l.errUserDisabled;
  return l.errUnexpected;
}

/// Maps any Firestore read/write failure to a short, honest message without
/// leaking raw errors.
String dataErrorMessage(BuildContext context, Object error) {
  final l = context.l10n;
  final code = error.toString().toLowerCase();
  if (code.contains('permission-denied')) return l.errPermission;
  if (code.contains('unavailable') ||
      code.contains('network') ||
      code.contains('failed')) {
    return l.errNetwork;
  }
  if (code.contains('not-found')) return l.errNotFound;
  return l.errGeneric;
}