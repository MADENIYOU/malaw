import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
import '../constants/locations.dart';
import '../theme/app_colors.dart';
import '../utils/date_fr.dart';

/// Carte d'une entrée du planning (une case du calendrier, indépendante).
/// Adresses choisies dans une liste mockée (pas de géocodage réel).
/// La répétition ("Se répète chaque semaine") vit ici, dans le formulaire —
/// façon Google Agenda — et "Copier vers..." reste un raccourci séparé pour
/// dupliquer cette entrée sur d'autres jours sans les lier entre eux.
class DayPlanCard extends StatelessWidget {
  final DateTime date;
  final String? adresseDepart;
  final String? destination;
  final String? heureArrivee;
  final Set<Weekday> repeatWeekdays;
  final ValueChanged<String?> onAdresseChanged;
  final ValueChanged<String?> onDestinationChanged;
  final ValueChanged<String> onHeureChanged;
  final ValueChanged<Set<Weekday>> onRepeatWeekdaysChanged;
  final VoidCallback onCopyToOthers;
  final VoidCallback onRemove;

  const DayPlanCard({
    super.key,
    required this.date,
    required this.adresseDepart,
    required this.destination,
    required this.heureArrivee,
    required this.repeatWeekdays,
    required this.onAdresseChanged,
    required this.onDestinationChanged,
    required this.onHeureChanged,
    required this.onRepeatWeekdaysChanged,
    required this.onCopyToOthers,
    required this.onRemove,
  });

  Future<void> _pickHeure(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      onHeureChanged('$h:$m');
    }
  }

  void _toggleSeRepete(bool active) {
    if (active) {
      final jourAncre = Weekday.values[date.weekday - 1];
      onRepeatWeekdaysChanged({jourAncre});
    } else {
      onRepeatWeekdaysChanged(const {});
    }
  }

  void _toggleWeekday(Weekday w, bool active) {
    final updated = Set<Weekday>.from(repeatWeekdays);
    if (active) {
      updated.add(w);
    } else {
      updated.remove(w);
    }
    onRepeatWeekdaysChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final seRepete = repeatWeekdays.isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFr.shortDate(date),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: onRemove,
                  tooltip: 'Retirer cette entrée',
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: adresseDepart,
              decoration: const InputDecoration(labelText: 'Adresse de départ'),
              items: AppLocations.dakarNeighborhoods
                  .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                  .toList(),
              onChanged: onAdresseChanged,
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _pickHeure(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: "Heure d'arrivée souhaitée",
                ),
                child: Text(heureArrivee ?? 'Choisir une heure'),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: destination,
              decoration: const InputDecoration(labelText: 'Destination'),
              items: AppLocations.dakarNeighborhoods
                  .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                  .toList(),
              onChanged: onDestinationChanged,
            ),
            const Divider(height: 28),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: seRepete,
              onChanged: _toggleSeRepete,
              activeThumbColor: AppColors.primary,
              title: const Text('Se répète chaque semaine'),
              subtitle: Text(
                seRepete
                    ? 'Les ${repeatWeekdays.map((w) => w.shortLabel).join(', ')}'
                    : 'Ne se répète pas (uniquement le ${DateFr.shortDate(date)})',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            if (seRepete) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: Weekday.values.map((w) {
                  final active = repeatWeekdays.contains(w);
                  return FilterChip(
                    label: Text(w.shortLabel),
                    selected: active,
                    onSelected: (v) => _toggleWeekday(w, v),
                    selectedColor: AppColors.primary.withValues(alpha: 0.18),
                    checkmarkColor: AppColors.primary,
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onCopyToOthers,
                icon: const Icon(Icons.copy_all_outlined, size: 16),
                label: const Text('Copier vers...'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
