import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/services/notification_service.dart';
import '../../core/state/session_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_fr.dart';
import '../../core/utils/friendly_error.dart';
import '../../core/utils/responsive_helper.dart';
import '../../core/utils/trip_tarif.dart';
import '../../core/utils/view_state.dart';
import '../../core/widgets/async_state_view.dart';
import '../../core/widgets/decorative_header_band.dart';
import '../../core/widgets/fill_gauge.dart';
import '../../core/widgets/trip_type_badge.dart';
import '../../data/models/enums.dart';
import '../../data/models/trip.dart';
import '../../data/repositories/trip_repository.dart';

/// Dashboard chauffeur : accueil, stats du jour, ce qu'il y a à faire, mes
/// trajets déjà assignés et demandes en attente. La jauge reste informative
/// (seuil de 4 non bloquant).
class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final _tripRepository = TripRepository();
  ViewState<_DashboardData> _state = const ViewState.loading();

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Future<void> _load() async {
    setState(() => _state = const ViewState.loading());
    try {
      final driverId = context.read<SessionProvider>().activeProfile!.id;
      final mesTrajets = await _tripRepository.getTripsForDriver(driverId);
      final demandes = await _tripRepository.getUnassignedTrips(limit: 20);

      final trajetsAujourdhui = mesTrajets
          .where((t) => _isToday(t.date))
          .toList();
      final gainsDuJour = trajetsAujourdhui.fold<int>(
        0,
        (sum, t) => sum + TripTarif.gain(t.mode, t.placesRemplies),
      );
      final aDemarrer = trajetsAujourdhui
          .where((t) => t.statut == TripStatus.confirme)
          .toList();

      final data = _DashboardData(
        mesTrajets: mesTrajets,
        demandes: demandes,
        nombreAujourdhui: trajetsAujourdhui.length,
        gainsDuJour: gainsDuJour,
        aDemarrer: aDemarrer,
      );
      setState(
        () => _state = mesTrajets.isEmpty && demandes.isEmpty
            ? const ViewState.empty()
            : ViewState.success(data),
      );
    } catch (e) {
      setState(() => _state = ViewState.error(friendlyError(e)));
    }
  }

  Future<void> _accepter(Trip trip) async {
    try {
      final driverId = context.read<SessionProvider>().activeProfile!.id;
      await _tripRepository.assignDriverAndConfirm(trip.id, driverId);
      await NotificationService.instance.trajetAccepte(_libelle(trip));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }

  String _libelle(Trip trip) => trip.mode == TripMode.interregions
      ? '${trip.villeDepart} → ${trip.villeArrivee}'
      : '${trip.adresseDepart} → ${trip.destination}';

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<SessionProvider>().activeProfile;
    final padding = ResponsiveHelper.horizontalPadding(context);
    final prenom = profile?.nom.split(' ').first ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Mes trajets')),
      body: SafeArea(
        child: AsyncStateView<_DashboardData>(
          state: _state,
          emptyMessage: 'Aucun trajet pour le moment.',
          onRetry: _load,
          builder: (context, data) => RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const DecorativeHeaderBand(),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: padding,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour $prenom',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Voici votre journée",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              icon: Icons.today_outlined,
                              label: "Trajets aujourd'hui",
                              value: '${data.nombreAujourdhui}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatTile(
                              icon: Icons.payments_outlined,
                              label: 'Gains du jour',
                              value: '${data.gainsDuJour} FCFA',
                            ),
                          ),
                        ],
                      ),
                      if (data.aDemarrer.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Card(
                          color: AppColors.sunAccent.withValues(alpha: 0.15),
                          child: ListTile(
                            leading: const Icon(
                              Icons.play_circle_outline,
                              color: AppColors.brown,
                            ),
                            title: Text(
                              '${data.aDemarrer.length} trajet(s) à démarrer aujourd\'hui',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(_libelle(data.aDemarrer.first)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push(
                              '/chauffeur/dashboard/trajet/${data.aDemarrer.first.id}',
                            ),
                          ),
                        ),
                      ],
                      if (data.mesTrajets.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Mes trajets',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        ...data.mesTrajets.map(
                          (trip) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => context.push(
                                  '/chauffeur/dashboard/trajet/${trip.id}',
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          TripTypeBadge(mode: trip.mode),
                                          const SizedBox(width: 8),
                                          Text(DateFr.shortDate(trip.date)),
                                          const Spacer(),
                                          Text(trip.heureRamassageEstimee),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _libelle(trip),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 10),
                                      FillGaugeWidget(
                                        placesRemplies: trip.placesRemplies,
                                        placesTotal: trip.placesTotal,
                                        confirme:
                                            trip.statut != TripStatus.enAttente,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (data.demandes.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          'Demandes en attente',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        ...data.demandes.map(
                          (trip) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Card(
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
                                      _libelle(trip),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 10),
                                    FillGaugeWidget(
                                      placesRemplies: trip.placesRemplies,
                                      placesTotal: trip.placesTotal,
                                    ),
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton(
                                        onPressed: () => _accepter(trip),
                                        child: const Text('Accepter ce trajet'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardData {
  final List<Trip> mesTrajets;
  final List<Trip> demandes;
  final int nombreAujourdhui;
  final int gainsDuJour;
  final List<Trip> aDemarrer;

  const _DashboardData({
    required this.mesTrajets,
    required this.demandes,
    required this.nombreAujourdhui,
    required this.gainsDuJour,
    required this.aDemarrer,
  });
}
