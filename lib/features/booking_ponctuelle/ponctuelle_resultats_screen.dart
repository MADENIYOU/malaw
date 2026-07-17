import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/friendly_error.dart';
import '../../core/utils/view_state.dart';
import '../../core/widgets/async_state_view.dart';
import '../../core/widgets/fill_gauge.dart';
import '../../data/models/trip.dart';
import '../../data/repositories/trip_repository.dart';

class PonctuelleResultatsScreen extends StatefulWidget {
  final String tripId;

  const PonctuelleResultatsScreen({super.key, required this.tripId});

  @override
  State<PonctuelleResultatsScreen> createState() =>
      _PonctuelleResultatsScreenState();
}

class _PonctuelleResultatsScreenState extends State<PonctuelleResultatsScreen> {
  final _tripRepository = TripRepository();
  ViewState<Trip> _state = const ViewState.loading();
  bool _joining = false;

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

  Future<void> _reserver() async {
    setState(() => _joining = true);
    try {
      await _tripRepository.joinTrip(widget.tripId);
      final trip = await _tripRepository.getTripById(widget.tripId);
      if (trip != null) {
        await NotificationService.instance.placeRejointe(
          '${trip.adresseDepart} → ${trip.destination}',
          trip.placesRemplies,
          trip.placesTotal,
        );
      }
      if (!mounted) return;
      context.go('/passager/home/ponctuelle-confirmation/${widget.tripId}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trajet disponible')),
      body: SafeArea(
        child: AsyncStateView<Trip>(
          state: _state,
          emptyMessage: "Ce trajet n'est plus disponible.",
          onRetry: _load,
          builder: (context, trip) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.route_outlined, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${trip.adresseDepart} → ${trip.destination}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ramassage estimé ${trip.heureRamassageEstimee} · '
                          'Arrivée souhaitée ${trip.heureArriveeSouhaitee}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        FillGaugeWidget(
                          placesRemplies: trip.placesRemplies,
                          placesTotal: trip.placesTotal,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _joining ? null : _reserver,
                  child: _joining
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Réserver ce trajet'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
