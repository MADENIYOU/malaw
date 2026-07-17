/// Pas de vrai calcul de distance/trafic (pas de backend). On recule l'heure
/// d'arrivée souhaitée d'un délai fixe représentant trajet + marge de
/// ramassage multi-passagers — déterministe pour rester prévisible en démo.
class PickupTimeCalculator {
  PickupTimeCalculator._();

  static const int intraCityBufferMinutes = 35;
  static const int interRegionBufferMinutes = 90;

  static String estimatePickupTime(
    String heureArriveeSouhaitee, {
    int bufferMinutes = intraCityBufferMinutes,
  }) {
    final parts = heureArriveeSouhaitee.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    var totalMinutes = hour * 60 + minute - bufferMinutes;
    totalMinutes %= 24 * 60;
    if (totalMinutes < 0) totalMinutes += 24 * 60;

    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
