import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/day_plan_card.dart';
import '../../core/widgets/month_calendar_grid.dart';
import '../../data/models/enums.dart';
import 'mensuelle_draft_entry.dart';

/// Créateur de planning mensuel — vrai calendrier mensuel, chaque case tapée
/// est une entrée indépendante ; la répétition (façon Google Agenda) et le
/// "copier vers..." se règlent dans le formulaire de chaque entrée.
class MensuelleCreerScreen extends StatefulWidget {
  const MensuelleCreerScreen({super.key});

  @override
  State<MensuelleCreerScreen> createState() => _MensuelleCreerScreenState();
}

class _MensuelleCreerScreenState extends State<MensuelleCreerScreen> {
  final Map<DateTime, MensuelleDraftEntry> _entries = {};
  String? _errorMessage;
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  void _previousMonth() {
    setState(
      () => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1),
    );
  }

  void _nextMonth() {
    setState(
      () => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1),
    );
  }

  void _onDayTap(DateTime date) {
    final key = _normalize(date);
    setState(() {
      if (_entries.containsKey(key)) {
        _entries.remove(key);
      } else {
        _entries[key] = MensuelleDraftEntry(date: key);
      }
    });
  }

  void _updateEntry(DateTime key, MensuelleDraftEntry updated) {
    setState(() => _entries[key] = updated);
  }

  void _removeEntry(DateTime key) {
    setState(() => _entries.remove(key));
  }

  DateTime _nextDateForWeekday(Weekday weekday) {
    final today = DateTime.now();
    final todayIndex = today.weekday;
    final targetIndex = weekday.index + 1;
    var diff = targetIndex - todayIndex;
    if (diff <= 0) diff += 7;
    return _normalize(today).add(Duration(days: diff));
  }

  Future<void> _copyToOthers(DateTime sourceKey) async {
    final source = _entries[sourceKey]!;
    final targets = await showDialog<Set<Weekday>>(
      context: context,
      builder: (context) => _CopyToDialog(excludeWeekday: source.jourAncre),
    );
    if (targets == null || targets.isEmpty) return;
    setState(() {
      for (final w in targets) {
        final date = _nextDateForWeekday(w);
        _entries[date] = MensuelleDraftEntry(
          date: date,
          adresseDepart: source.adresseDepart,
          heureArrivee: source.heureArrivee,
          destination: source.destination,
        );
      }
    });
  }

  void _validateAndProceed() {
    if (_entries.isEmpty) {
      setState(
        () => _errorMessage = 'Tapez au moins un jour dans le calendrier.',
      );
      return;
    }
    if (_entries.values.any((e) => !e.isComplete)) {
      setState(
        () => _errorMessage = 'Complétez toutes les entrées avant de continuer.',
      );
      return;
    }
    setState(() => _errorMessage = null);
    final ordered = _entries.keys.toList()..sort();
    context.push(
      '/passager/home/mensuelle/recap',
      extra: ordered.map((k) => _entries[k]!).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordered = _entries.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('Créer mon planning')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.brown.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event_repeat_outlined,
                    color: AppColors.brown,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tapez sur un jour pour ajouter un trajet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Chaque jour est indépendant : la répétition se règle '
                        'dans son formulaire, comme sur un agenda.',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: MonthCalendarGrid(
                  month: _visibleMonth,
                  isActive: (d) => _entries.containsKey(_normalize(d)),
                  onDayTap: _onDayTap,
                  onPreviousMonth: _previousMonth,
                  onNextMonth: _nextMonth,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ...ordered.map((key) {
              final entry = _entries[key]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DayPlanCard(
                  date: key,
                  adresseDepart: entry.adresseDepart,
                  destination: entry.destination,
                  heureArrivee: entry.heureArrivee,
                  repeatWeekdays: entry.repeatWeekdays,
                  onAdresseChanged: (v) =>
                      _updateEntry(key, entry.copyWith(adresseDepart: v)),
                  onDestinationChanged: (v) =>
                      _updateEntry(key, entry.copyWith(destination: v)),
                  onHeureChanged: (v) =>
                      _updateEntry(key, entry.copyWith(heureArrivee: v)),
                  onRepeatWeekdaysChanged: (w) =>
                      _updateEntry(key, entry.copyWith(repeatWeekdays: w)),
                  onCopyToOthers: () => _copyToOthers(key),
                  onRemove: () => _removeEntry(key),
                ),
              );
            }),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _validateAndProceed,
              child: const Text('Voir le récapitulatif'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CopyToDialog extends StatefulWidget {
  final Weekday excludeWeekday;

  const _CopyToDialog({required this.excludeWeekday});

  @override
  State<_CopyToDialog> createState() => _CopyToDialogState();
}

class _CopyToDialogState extends State<_CopyToDialog> {
  final Set<Weekday> _selected = {};

  @override
  Widget build(BuildContext context) {
    final options = Weekday.values
        .where((w) => w != widget.excludeWeekday)
        .toList();
    return AlertDialog(
      title: const Text('Copier vers...'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: options
              .map(
                (w) => CheckboxListTile(
                  value: _selected.contains(w),
                  title: Text(w.fullLabel),
                  subtitle: const Text('Prochaine occurrence, en copie indépendante'),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _selected.add(w);
                    } else {
                      _selected.remove(w);
                    }
                  }),
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('Copier'),
        ),
      ],
    );
  }
}
