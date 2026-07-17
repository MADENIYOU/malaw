/// Formatage de date en français, sans dépendre des données de locale intl
/// (évite un risque de plantage si la locale 'fr_FR' n'est pas initialisée).
class DateFr {
  DateFr._();

  static const _mois = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];

  static const _joursCourts = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

  static const joursCourtsHeader = _joursCourts;

  static const _moisComplets = [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre',
  ];

  static String shortDate(DateTime date) {
    final jour = _joursCourts[date.weekday - 1];
    final mois = _mois[date.month - 1];
    return '$jour ${date.day} $mois';
  }

  static String monthYear(DateTime date) =>
      '${_moisComplets[date.month - 1]} ${date.year}';
}
