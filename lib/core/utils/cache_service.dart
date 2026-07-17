/// Cache in-memory simple pour les listings peu volatils (quartiers, villes,
/// profil actif). Pas de backend => pas de staleness serveur à gérer : on
/// invalide explicitement à l'écriture plutôt que via un TTL temporel.
class CacheService {
  CacheService._internal();

  static final CacheService instance = CacheService._internal();

  final Map<String, dynamic> _store = {};

  T? read<T>(String key) => _store[key] as T?;

  void write<T>(String key, T value) {
    _store[key] = value;
  }

  void invalidate(String key) {
    _store.remove(key);
  }

  void invalidateWhere(bool Function(String key) test) {
    _store.removeWhere((key, _) => test(key));
  }

  void clear() {
    _store.clear();
  }
}
