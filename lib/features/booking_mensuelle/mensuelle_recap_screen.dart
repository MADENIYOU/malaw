import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/services/notification_service.dart';
import '../../core/state/session_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_fr.dart';
import '../../core/utils/friendly_error.dart';
import '../../data/models/enums.dart';
import '../../data/models/planning_entry.dart';
import '../../data/repositories/planning_repository.dart';
import 'mensuelle_draft_entry.dart';

class MensuelleRecapScreen extends StatefulWidget {
  final List<MensuelleDraftEntry> draftEntries;

  const MensuelleRecapScreen({super.key, required this.draftEntries});

  @override
  State<MensuelleRecapScreen> createState() => _MensuelleRecapScreenState();
}

class _MensuelleRecapScreenState extends State<MensuelleRecapScreen> {
  final _planningRepository = PlanningRepository();
  bool _submitting = false;

  Future<void> _confirmer() async {
    setState(() => _submitting = true);
    final passengerId = context.read<SessionProvider>().activeProfile!.id;
    try {
      final planning = await _planningRepository.createOrGetPlanning(
        passengerId,
      );
      for (final draft in widget.draftEntries) {
        final entry = PlanningEntry(
          id: 'entry_${planning.id}_${draft.date.toIso8601String().substring(0, 10)}',
          planningId: planning.id,
          date: draft.date,
          adresseDepart: draft.adresseDepart!,
          heureArrivee: draft.heureArrivee!,
          destination: draft.destination!,
          repeatWeekdays: draft.repeatWeekdays,
        );
        await _planningRepository.saveEntry(entry);
        await _planningRepository.generateOccurrences(entry, passengerId);
        await NotificationService.instance.planningJourGenere(
          entry.seRepete
              ? entry.repeatWeekdays.map((w) => w.shortLabel).join(', ')
              : DateFr.shortDate(entry.date),
          '${entry.adresseDepart} → ${entry.destination}',
        );
      }
      if (!mounted) return;
      context.go('/passager/home/mensuelle/mon-planning');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Récapitulatif du planning')),
      body: SafeArea(
        child: widget.draftEntries.isEmpty
            ? const Center(child: Text('Aucune entrée à récapituler.'))
            : Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: widget.draftEntries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final d = widget.draftEntries[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 88,
                                  child: Text(
                                    DateFr.shortDate(d.date),
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${d.adresseDepart} → ${d.destination}'),
                                      Text(
                                        'Arrivée à ${d.heureArrivee}',
                                        style: Theme.of(context).textTheme.bodySmall
                                            ?.copyWith(color: AppColors.textSecondary),
                                      ),
                                      if (d.seRepete)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            'Se répète : ${d.repeatWeekdays.map((w) => w.shortLabel).join(', ')}',
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _confirmer,
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Confirmer le planning'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
