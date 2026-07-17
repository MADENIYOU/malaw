import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notifications "push" simulées en local : pas de backend donc pas de vrai
/// FCM/APNs — l'app déclenche elle-même une notification locale aux moments
/// importants du cycle de vie d'un trajet (confirmation, chauffeur assigné,
/// en route, terminé, nouvelle demande côté chauffeur).
class NotificationService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  int _nextId = 0;

  Future<void> init() async {
    if (_initialized) return;
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );
      await _plugin.initialize(settings: initSettings);

      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidImpl?.requestNotificationsPermission();

      _initialized = true;
    } catch (e) {
      debugPrint('Initialisation notifications échouée: $e');
    }
  }

  Future<void> _show(String title, String body) async {
    if (!_initialized) return;
    const androidDetails = AndroidNotificationDetails(
      'covoiturage_important',
      'Notifications importantes',
      channelDescription:
          'Confirmations de trajet, chauffeur assigné, suivi en direct',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    try {
      await _plugin.show(
        id: _nextId++,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('Notification échouée: $e');
    }
  }

  Future<void> tripConfirme(String trajet) => _show(
    'Trajet confirmé ✓',
    'Votre trajet $trajet est confirmé, un chauffeur vous a été assigné.',
  );

  Future<void> tripEnRoute(String trajet) => _show(
    'Chauffeur en route',
    'Votre chauffeur est en route pour $trajet.',
  );

  Future<void> tripTermine(String trajet) =>
      _show('Trajet terminé', 'Votre trajet $trajet est terminé. Merci !');

  Future<void> placeRejointe(String trajet, int remplies, int total) => _show(
    'Réservation prise en compte',
    '$trajet : $remplies/$total places remplies.',
  );

  Future<void> planningJourGenere(String jour, String trajet) => _show(
    'Planning mis à jour',
    'Un trajet a été généré pour $jour : $trajet.',
  );

  Future<void> nouvelleDemandeChauffeur(String trajet) => _show(
    'Nouvelle demande de trajet',
    'Une nouvelle demande est disponible : $trajet.',
  );

  Future<void> trajetAccepte(String trajet) => _show(
    'Trajet accepté',
    'Vous avez accepté le trajet $trajet. Il apparaît dans vos trajets du jour.',
  );
}
