import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// True for errors that mean "no network", so work can be queued for later.
bool isNetworkError(Object e) {
  if (e is SocketException || e is TimeoutException || e is HandshakeException) return true;
  if (e is AuthRetryableFetchException) return true;
  final s = e.toString();
  return s.contains('SocketException') ||
      s.contains('Failed host lookup') ||
      s.contains('Connection closed') ||
      s.contains('Connection refused') ||
      s.contains('ClientException') ||
      s.contains('Network is unreachable');
}

/// True for errors that retrying will not fix (permission, business rule).
bool isPermanentError(Object e) {
  if (e is PostgrestException) {
    // 42501 = not allowed; P0001 = raise exception in an RPC (business rule)
    return e.code == '42501' || e.code == 'P0001' || e.code == '23505' || e.code == '23514';
  }
  return false;
}

/// A message to show a person. Server rules raise readable messages
/// ("you must be at the outlet to submit"), so those are passed through.
String friendlyError(Object e) {
  if (isNetworkError(e)) return 'No connection. Try again when you are back online.';
  if (e is PostgrestException) {
    if (e.code == '42501') {
      final m = e.message;
      return m == 'not allowed' ? 'You are not allowed to do this.' : _capitalize(m);
    }
    return _capitalize(e.message);
  }
  if (e is AuthException) return e.message;
  if (e is StorageException) return e.message;
  if (e is FunctionException) {
    final details = e.details;
    if (details is Map && details['error'] != null) return details['error'].toString();
    return 'Server error (${e.status}).';
  }
  final s = e.toString();
  return s.startsWith('Exception: ') ? s.substring(11) : s;
}

String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
