import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/friendly_error.dart';
import '../../core/utils/pickup_stops_builder.dart';
import '../../core/utils/view_state.dart';
import '../../core/widgets/async_state_view.dart';
import '../../core/widgets/fill_gauge.dart';
import '../../core/widgets/pickup_timeline.dart';
import '../../data/models/enums.dart';
import '../../data/models/trip.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/trip_repository.dart';

class DriverTripDetailScreen extends StatefulWidget {
  final String tripId;

  const DriverTripDetailScreen({super.key, required this.tripId});

  @override
  State<DriverTripDetailScreen> createState() =>
      _DriverTripDetailScreenState();
}

class _DriverTripDetailScreenState extends State<DriverTripDetailScreen> {
  final _tripRepository = TripRepository();
  final _profileRepository = ProfileRepository();
  ViewState<_DetailData> _state = const ViewState.loading();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const ViewState.loading());
    try {
      final trip = await _tripRepository.getTripById(widget.tripId);
      if (trip == null) {
        setState(() => _state = const ViewState.empty());
        return;
      }
      final passenger = await _profileRepository.getProfileById(
        trip.passengerId,
      );
      if (passenger == null) {
        setState(() => _state = const ViewState.empty());
        return;
      }
      setState(
        () => _state = ViewState.success(
          _DetailData(trip: trip, passenger: passenger),
        ),
      );
    } catch (e) {
      setState(() => _state = ViewState.error(friendlyError(e)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail du trajet')),
      body: SafeArea(
        child: AsyncStateView<_DetailData>(
          state: _state,
          onRetry: _load,
          builder: (context, data) {
            final trip = data.trip;
            final stops = PickupStopsBuilder.build(
              trip: trip,
              realPassenger: data.passenger,
            );
            final peutDemarrer = trip.statut == TripStatus.confirme;
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FillGaugeWidget(
                    placesRemplies: trip.placesRemplies,
                    placesTotal: trip.placesTotal,
                    confirme: trip.statut != TripStatus.enAttente,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Ordre de ramassage',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: PickupTimelineWidget(stops: stops),
                    ),
                  ),
                  if (peutDemarrer)
                    ElevatedButton(
                      onPressed: () => context.push(
                        '/chauffeur/dashboard/trajet/${trip.id}/en-cours',
                      ),
                      child: const Text('Démarrer la tournée'),
                    )
                  else
                    Text(
                      'En attente de confirmation (la jauge ne bloque pas le départ).',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DetailData {
  final Trip trip;
  final UserProfile passenger;

  const _DetailData({required this.trip, required this.passenger});
}
