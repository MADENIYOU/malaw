import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/notification_service.dart';
import '../../core/utils/friendly_error.dart';
import '../../core/utils/pickup_stops_builder.dart';
import '../../core/utils/view_state.dart';
import '../../core/widgets/async_state_view.dart';
import '../../core/widgets/pickup_timeline.dart';
import '../../data/models/enums.dart';
import '../../data/models/trip.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/trip_repository.dart';

class DriverTripInProgressScreen extends StatefulWidget {
  final String tripId;

  const DriverTripInProgressScreen({super.key, required this.tripId});

  @override
  State<DriverTripInProgressScreen> createState() =>
      _DriverTripInProgressScreenState();
}

class _DriverTripInProgressScreenState
    extends State<DriverTripInProgressScreen> {
  final _tripRepository = TripRepository();
  final _profileRepository = ProfileRepository();
  ViewState<_ProgressData> _state = const ViewState.loading();
  List<bool> _recupereFlags = [];

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
      if (trip.statut == TripStatus.confirme) {
        await _tripRepository.updateStatus(widget.tripId, TripStatus.enRoute);
      }
      final passenger = await _profileRepository.getProfileById(
        trip.passengerId,
      );
      if (passenger == null) {
        setState(() => _state = const ViewState.empty());
        return;
      }
      final count = trip.placesRemplies == 0 ? 1 : trip.placesRemplies;
      _recupereFlags = List.filled(count, false);
      setState(
        () => _state = ViewState.success(
          _ProgressData(trip: trip, passenger: passenger),
        ),
      );
    } catch (e) {
      setState(() => _state = ViewState.error(friendlyError(e)));
    }
  }

  void _marquerRecupere(int index) {
    setState(() => _recupereFlags[index] = true);
  }

  Future<void> _terminer() async {
    try {
      final trip = await _tripRepository.getTripById(widget.tripId);
      await _tripRepository.updateStatus(widget.tripId, TripStatus.termine);
      if (trip != null) {
        final libelle = trip.mode == TripMode.interregions
            ? '${trip.villeDepart} → ${trip.villeArrivee}'
            : '${trip.adresseDepart} → ${trip.destination}';
        await NotificationService.instance.tripTermine(libelle);
      }
      if (!mounted) return;
      context.go('/chauffeur/dashboard');
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
      appBar: AppBar(title: const Text('Trajet en cours')),
      body: SafeArea(
        child: AsyncStateView<_ProgressData>(
          state: _state,
          onRetry: _load,
          builder: (context, data) {
            final stops = PickupStopsBuilder.build(
              trip: data.trip,
              realPassenger: data.passenger,
              recupereFlags: _recupereFlags,
            );
            final tousRecuperes = _recupereFlags.every((r) => r);
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: PickupTimelineWidget(
                        stops: stops,
                        onMarkPickedUp: _marquerRecupere,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: tousRecuperes ? _terminer : null,
                    child: const Text('Terminer le trajet'),
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

class _ProgressData {
  final Trip trip;
  final UserProfile passenger;

  const _ProgressData({required this.trip, required this.passenger});
}
