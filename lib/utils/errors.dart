import 'dart:async';

import 'package:flutter/material.dart';
import '../l10n/ext.dart';

/// Maps any auth/social-sign-in failure to a short, honest, user-facing
/// message. Social providers report walled flows (cancel, SHA-1 mismatch,
/// disabled provider) as differently-shaped exceptions, so we normalize the
/// string to lowercase and match recognizable fragments.
///
/// Supabase surfaces failures as `AuthException`/`GoogleSignInException`;
/// the recognized fragments cover both those and legacy strings.
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
      msg.contains('admin-restricted-operation') ||
      msg.contains('signups not allowed') ||
      msg.contains('email logins are disabled') ||
      msg.contains('provider is not enabled')) {
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
      msg.contains('invalid-credential') ||
      msg.contains('invalid login credentials')) {
    return l.errBadCredentials;
  }
  if (msg.contains('email-already-in-use') ||
      msg.contains('already registered') ||
      msg.contains('already exists') ||
      msg.contains('user already')) {
    return l.errEmailInUse;
  }
  if (msg.contains('weak-password') ||
      msg.contains('password should be at least') ||
      msg.contains('password is too short')) {
    return l.errWeakPassword;
  }
  if (msg.contains('invalid-email') ||
      msg.contains('unable to validate email') ||
      msg.contains('email address') && msg.contains('invalid')) {
    return l.errInvalidEmail;
  }
  if (msg.contains('network-request-failed') ||
      msg.contains('network') ||
      msg.contains('socketexception') ||
      msg.contains('clientexception') ||
      msg.contains('failed host lookup') ||
      msg.contains('connection failed')) {
    return l.errNetwork;
  }
  if (msg.contains('too-many-requests') ||
      msg.contains('too many requests') ||
      msg.contains('rate limit') ||
      msg.contains('for security purposes')) {
    return l.errTooMany;
  }
  if (msg.contains('user-disabled') ||
      msg.contains('user is banned') ||
      msg.contains('banned')) {
    return l.errUserDisabled;
  }
  return l.errUnexpected;
}

/// Maps any read/write failure (PostgREST, Storage, RLS) to a short, honest
/// message without leaking raw errors.
String dataErrorMessage(BuildContext context, Object error) {
  final l = context.l10n;
  final code = error.toString().toLowerCase();
  if (code.contains('permission-denied') ||
      code.contains('row-level security') ||
      code.contains('insufficient privilege') ||
      code.contains('not an admin') ||
      code.contains('not allowed') ||
      code.contains('only the') ||
      code.contains('cannot ') ||
      code.contains('jwt') ||
      code.contains('invalid api key') ||
      code.contains('42501')) {
    return l.errPermission;
  }
  if (code.contains('unavailable') ||
      code.contains('network') ||
      code.contains('socketexception') ||
      code.contains('clientexception') ||
      code.contains('failed host lookup') ||
      code.contains('connection') ||
      code.contains('failed')) {
    return l.errNetwork;
  }
  if (code.contains('not-found') ||
      code.contains('pgrst116') ||
      code.contains('no rows')) {
    return l.errNotFound;
  }
  return l.errGeneric;
}
