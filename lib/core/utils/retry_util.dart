import 'dart:async';
import 'dart:math';

/// Erreur volontairement non retentée (ex: validation, contrainte de donnée)
/// — l'équivalent local d'un "4xx" qu'on ne réessaie jamais.
class NonRetryableException implements Exception {
  final String message;
  NonRetryableException(this.message);

  @override
  String toString() => message;
}

/// Réessaie [action] jusqu'à [maxAttempts] fois avec un backoff exponentiel,
/// sauf si l'erreur est une [NonRetryableException]. Utilisé autour des
/// opérations SQLite qui peuvent échouer de façon transitoire (ex: DB
/// verrouillée par une autre écriture).
Future<T> withRetry<T>(
  Future<T> Function() action, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(milliseconds: 200),
}) async {
  var attempt = 0;
  while (true) {
    attempt++;
    try {
      return await action();
    } on NonRetryableException {
      rethrow;
    } catch (_) {
      if (attempt >= maxAttempts) rethrow;
      await Future.delayed(initialDelay * pow(2, attempt - 1));
    }
  }
}
