import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/session_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_fr.dart';
import '../../core/utils/friendly_error.dart';
import '../../core/utils/trip_tarif.dart';
import '../../core/utils/view_state.dart';
import '../../core/widgets/async_state_view.dart';
import '../../core/widgets/decorative_header_band.dart';
import '../../core/widgets/trip_type_badge.dart';
import '../../data/models/enums.dart';
import '../../data/models/trip.dart';
import '../../data/repositories/trip_repository.dart';

/// Historique + gains mockés. Le gain est proportionnel aux places
/// effectivement remplies (jamais aux places vides), cohérent avec la
/// règle métier du seuil de 4 non bloquant.
class DriverHistoriqueScreen extends StatefulWidget {
  const DriverHistoriqueScreen({super.key});

  @override
  State<DriverHistoriqueScreen> createState() => _DriverHistoriqueScreenState();
}

class _DriverHistoriqueScreenState extends State<DriverHistoriqueScreen> {
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
      final driverId = context.read<SessionProvider>().activeProfile!.id;
      final trips = await _tripRepository.getTripsForDriver(driverId);
      final termines = trips
          .where((t) => t.statut == TripStatus.termine)
          .toList();
      setState(
        () => _state = termines.isEmpty
            ? const ViewState.empty()
            : ViewState.success(termines),
      );
    } catch (e) {
      setState(() => _state = ViewState.error(friendlyError(e)));
    }
  }

  int _gain(Trip trip) => TripTarif.gain(trip.mode, trip.placesRemplies);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique et gains')),
      body: SafeArea(
        child: Column(
          children: [
            const DecorativeHeaderBand(),
            Expanded(
              child: AsyncStateView<List<Trip>>(
                state: _state,
                emptyMessage: 'Aucun trajet terminé pour le moment.',
                onRetry: _load,
                builder: (context, trips) {
                  final total = trips.fold<int>(0, (sum, t) => sum + _gain(t));
                  return RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Card(
                          color: AppColors.success.withValues(alpha: 0.12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gains estimés',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$total FCFA',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(color: AppColors.success),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Calculé uniquement sur les places occupées.',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ...trips.map(
                          (trip) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              TripTypeBadge(mode: trip.mode),
                                              const SizedBox(width: 8),
                                              Text(DateFr.shortDate(trip.date)),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            trip.mode == TripMode.interregions
                                                ? '${trip.villeDepart} → ${trip.villeArrivee}'
                                                : '${trip.adresseDepart} → ${trip.destination}',
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${_gain(trip)} FCFA',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(color: AppColors.success),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
