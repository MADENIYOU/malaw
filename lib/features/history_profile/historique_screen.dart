import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/session_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_fr.dart';
import '../../core/utils/friendly_error.dart';
import '../../core/utils/view_state.dart';
import '../../core/widgets/async_state_view.dart';
import '../../core/widgets/decorative_header_band.dart';
import '../../core/widgets/trip_type_badge.dart';
import '../../data/models/enums.dart';
import '../../data/models/trip.dart';
import '../../data/repositories/trip_repository.dart';

/// Historique tous modes confondus (ponctuelle/mensuelle/inter-régions),
/// paginé (LIMIT) pour rester scalable.
class HistoriqueScreen extends StatefulWidget {
  const HistoriqueScreen({super.key});

  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> {
  final _tripRepository = TripRepository();
  ViewState<List<Trip>> _state = const ViewState.loading();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const ViewState.loading());
    try {
      final passengerId = context.read<SessionProvider>().activeProfile!.id;
      final trips = await _tripRepository.getTripsForPassenger(
        passengerId,
        limit: 50,
      );
      setState(
        () => _state = trips.isEmpty
            ? const ViewState.empty()
            : ViewState.success(trips),
      );
    } catch (e) {
      setState(() => _state = ViewState.error(friendlyError(e)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: SafeArea(
        child: Column(
          children: [
            const DecorativeHeaderBand(),
            Expanded(
              child: AsyncStateView<List<Trip>>(
                state: _state,
                emptyMessage: "Vous n'avez pas encore de trajet.",
                onRetry: _load,
                builder: (context, trips) => RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: trips.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      final trajet = trip.mode == TripMode.interregions
                          ? '${trip.villeDepart} → ${trip.villeArrivee}'
                          : '${trip.adresseDepart} → ${trip.destination}';
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  TripTypeBadge(mode: trip.mode),
                                  const SizedBox(width: 8),
                                  Text(DateFr.shortDate(trip.date)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                trajet,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                trip.statut.label,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
