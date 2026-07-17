import '../../data/models/trip.dart';
import '../../data/models/user_profile.dart';
import '../constants/mock_passengers.dart';
import '../widgets/pickup_timeline.dart';

/// Construit la timeline de ramassage ordonnée à partir d'un [Trip] : le
/// passager démo réel + des passagers mockés pour les places restantes
/// (pas de vraie table multi-passagers dans ce prototype).
class PickupStopsBuilder {
  PickupStopsBuilder._();

  static List<PickupStop> build({
    required Trip trip,
    required UserProfile realPassenger,
    List<bool>? recupereFlags,
  }) {
    final count = trip.placesRemplies == 0 ? 1 : trip.placesRemplies;
    final baseMinutes = _parseMinutes(trip.heureRamassageEstimee);

    return List.generate(count, (i) {
      final isReal = i == 0;
      final label = isReal
          ? realPassenger.nom
          : MockPassengers.names[i % MockPassengers.names.length];
      return PickupStop(
        label: label,
        heure: _formatMinutes(baseMinutes + i * 5),
        isCurrentUser: isReal,
        recupere: recupereFlags != null && i < recupereFlags.length
            ? recupereFlags[i]
            : false,
      );
    });
  }

  static int _parseMinutes(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  static String _formatMinutes(int totalMinutes) {
    final m = totalMinutes % (24 * 60);
    final h = m ~/ 60;
    final min = m % 60;
    return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
  }
}
