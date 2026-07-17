import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/state/session_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_fr.dart';
import '../../core/utils/friendly_error.dart';
import '../../core/utils/view_state.dart';
import '../../core/widgets/async_state_view.dart';
import '../../core/widgets/fill_gauge.dart';
import '../../data/models/enums.dart';
import '../../data/models/planning_entry.dart';
import '../../data/models/trip.dart';
import '../../data/repositories/planning_repository.dart';
import '../../data/repositories/trip_repository.dart';

class MonPlanningScreen extends StatefulWidget {
  const MonPlanningScreen({super.key});

  @override
  State<MonPlanningScreen> createState() => _MonPlanningScreenState();
}

class _MonPlanningScreenState extends State<MonPlanningScreen> {
  final _planningRepository = PlanningRepository();
  final _tripRepository = TripRepository();
  ViewState<List<PlanningEntry>> _state = const ViewState.loading();
  final Map<String, Trip?> _nextTripByEntry = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const ViewState.loading());
    try {
      final passengerId = context.read<SessionProvider>().activeProfile!.id;
      final planning = await _planningRepository.getPlanningForPassenger(
        passengerId,
      );
      if (planning == null) {
        setState(() => _state = const ViewState.empty());
        return;
      }
      final entries = await _planningRepository.getEntries(planning.id);
      if (entries.isEmpty) {
        setState(() => _state = const ViewState.empty());
        return;
      }
      for (final e in entries) {
        _nextTripByEntry[e.id] = await _tripRepository
            .getNextTripForPlanningEntry(e.id);
      }
      setState(() => _state = ViewState.success(entries));
    } catch (e) {
      setState(() => _state = ViewState.error(friendlyError(e)));
    }
  }

  Future<void> _toggleActif(PlanningEntry entry, bool actif) async {
    try {
      await _planningRepository.setEntryActif(entry.id, actif);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }

  Future<void> _supprimer(PlanningEntry entry) async {
    try {
      await _planningRepository.deleteEntry(entry.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon planning'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter des jours',
            onPressed: () => context.push('/passager/home/mensuelle/creer'),
          ),
        ],
      ),
      body: SafeArea(
        child: AsyncStateView<List<PlanningEntry>>(
          state: _state,
          emptyMessage:
              "Vous n'avez pas encore de planning mensuel.\nCréez-en un pour vos trajets réguliers.",
          onRetry: _load,
          builder: (context, entries) => ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final trip = _nextTripByEntry[entry.id];
              final label = entry.seRepete
                  ? 'Se répète : ${entry.repeatWeekdays.map((w) => w.shortLabel).join(', ')}'
                  : 'Le ${DateFr.shortDate(entry.date)}';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Switch(
                            value: entry.actif,
                            onChanged: (v) => _toggleActif(entry, v),
                            activeThumbColor: AppColors.primary,
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.textSecondary,
                            ),
                            tooltip: 'Supprimer cette entrée',
                            onPressed: () => _supprimer(entry),
                          ),
                        ],
                      ),
                      Text('${entry.adresseDepart} → ${entry.destination}'),
                      Text(
                        'Arrivée à ${entry.heureArrivee}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                      if (entry.actif) ...[
                        const SizedBox(height: 10),
                        if (trip != null)
                          FillGaugeWidget(
                            placesRemplies: trip.placesRemplies,
                            placesTotal: trip.placesTotal,
                          )
                        else
                          const Text(
                            "Aucune occurrence à venir pour l'instant.",
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
