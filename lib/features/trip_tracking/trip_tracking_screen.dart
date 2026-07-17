import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/services/notification_service.dart';
import '../../core/state/session_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/friendly_error.dart';
import '../../core/utils/pickup_stops_builder.dart';
import '../../core/utils/view_state.dart';
import '../../core/widgets/async_state_view.dart';
import '../../core/widgets/pickup_timeline.dart';
import '../../core/widgets/trip_progress_stepper.dart';
import '../../data/models/enums.dart';
import '../../data/models/trip.dart';
import '../../data/repositories/trip_repository.dart';

/// Suivi simulé (pas de vrai GPS/backend) : un minuteur mocké fait avancer
/// le trajet vers "terminé". Écran terminal : le retour arrière système va
/// à l'accueil plutôt que de rouvrir la confirmation déjà validée.
class TripTrackingScreen extends StatefulWidget {
  final String tripId;

  const TripTrackingScreen({super.key, required this.tripId});

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen> {
  final _tripRepository = TripRepository();
  ViewState<Trip> _state = const ViewState.loading();
  Timer? _timer;
  int _minutesRestantes = 12;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _libelle(Trip trip) => trip.mode == TripMode.interregions
      ? '${trip.villeDepart} → ${trip.villeArrivee}'
      : '${trip.adresseDepart} → ${trip.destination}';

  Future<void> _load() async {
    setState(() => _state = const ViewState.loading());
    try {
      final trip = await _tripRepository.getTripById(widget.tripId);
      if (trip == null) {
        setState(() => _state = const ViewState.empty());
        return;
      }
      setState(() => _state = ViewState.success(trip));
      if (trip.statut == TripStatus.confirme) {
        await _tripRepository.updateStatus(widget.tripId, TripStatus.enRoute);
        await NotificationService.instance.tripEnRoute(_libelle(trip));
        _startSimulation();
      } else if (trip.statut == TripStatus.enRoute) {
        _startSimulation();
      }
    } catch (e) {
      setState(() => _state = ViewState.error(friendlyError(e)));
    }
  }

  void _startSimulation() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) return;
      setState(() => _minutesRestantes = (_minutesRestantes - 1).clamp(0, 999));
      if (_minutesRestantes <= 0) {
        timer.cancel();
        final trip = await _tripRepository.getTripById(widget.tripId);
        await _tripRepository.updateStatus(widget.tripId, TripStatus.termine);
        if (trip != null) {
          await NotificationService.instance.tripTermine(_libelle(trip));
        }
        if (mounted) _load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<SessionProvider>().activeProfile!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go('/passager/home');
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Suivi du trajet')),
        body: SafeArea(
          child: AsyncStateView<Trip>(
            state: _state,
            onRetry: _load,
            builder: (context, trip) {
              final stops = PickupStopsBuilder.build(
                trip: trip,
                realPassenger: profile,
              );
              final termine = trip.statut == TripStatus.termine;
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!termine)
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Container(
                            height: 170,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE9E4D8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: Image.asset(
                              'assets/illustrations/kirikou_car_map_icon.jpg',
                              height: 90,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Arrivée prévue',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                    Text(
                                      '$_minutesRestantes min',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (!termine) const SizedBox(height: 16),
                    TripProgressStepper(statut: trip.statut),
                    const SizedBox(height: 16),
                    Text(
                      termine
                          ? 'Trajet terminé'
                          : 'Chauffeur en route · arrive dans $_minutesRestantes min',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        child: PickupTimelineWidget(stops: stops),
                      ),
                    ),
                    if (termine)
                      ElevatedButton(
                        onPressed: () => context.go('/passager/home'),
                        child: const Text("Retour à l'accueil"),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
