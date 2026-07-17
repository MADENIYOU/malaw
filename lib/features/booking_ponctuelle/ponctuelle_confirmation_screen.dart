import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/friendly_error.dart';
import '../../core/utils/view_state.dart';
import '../../core/widgets/async_state_view.dart';
import '../../core/widgets/fill_gauge.dart';
import '../../data/models/enums.dart';
import '../../data/models/trip.dart';
import '../../data/repositories/driver_repository.dart';
import '../../data/repositories/trip_repository.dart';

class PonctuelleConfirmationScreen extends StatefulWidget {
  final String tripId;

  const PonctuelleConfirmationScreen({super.key, required this.tripId});

  @override
  State<PonctuelleConfirmationScreen> createState() =>
      _PonctuelleConfirmationScreenState();
}

class _PonctuelleConfirmationScreenState
    extends State<PonctuelleConfirmationScreen> {
  final _tripRepository = TripRepository();
  final _driverRepository = DriverRepository();
  ViewState<Trip> _state = const ViewState.loading();
  bool _simulating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const ViewState.loading());
    try {
      final trip = await _tripRepository.getTripById(widget.tripId);
      setState(
        () => _state = trip == null
            ? const ViewState.empty()
            : ViewState.success(trip),
      );
    } catch (e) {
      setState(() => _state = ViewState.error(friendlyError(e)));
    }
  }

  Future<void> _simulerConfirmation() async {
    setState(() => _simulating = true);
    try {
      final drivers = await _driverRepository.getAllDrivers();
      await _tripRepository.assignDriverAndConfirm(
        widget.tripId,
        drivers.first.id,
      );
      final trip = await _tripRepository.getTripById(widget.tripId);
      if (trip != null) {
        await NotificationService.instance.tripConfirme(
          '${trip.adresseDepart} → ${trip.destination}',
        );
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => _simulating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go('/passager/home');
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Confirmation')),
        body: SafeArea(
          child: AsyncStateView<Trip>(
            state: _state,
            onRetry: _load,
            builder: (context, trip) {
              final confirme = trip.statut == TripStatus.confirme;
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (confirme) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/illustrations/hero_horse_confetti.jpg',
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/illustrations/tamtam_icon.jpg',
                            height: 32,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tam-tam !',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          'Votre commande est confirmée.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    FillGaugeWidget(
                      placesRemplies: trip.placesRemplies,
                      placesTotal: trip.placesTotal,
                      confirme: confirme,
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${trip.adresseDepart} → ${trip.destination}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ramassage estimé à ${trip.heureRamassageEstimee}',
                            ),
                            if (confirme) ...[
                              const SizedBox(height: 6),
                              const Text('Chauffeur assigné ✓'),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (!confirme)
                      OutlinedButton(
                        onPressed: _simulating ? null : _simulerConfirmation,
                        child: _simulating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Simuler l'approche de l'heure de passage",
                              ),
                      ),
                    if (confirme) ...[
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.go(
                          '/passager/home/ponctuelle-suivi/${trip.id}',
                        ),
                        child: const Text('Suivre le trajet'),
                      ),
                    ],
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
