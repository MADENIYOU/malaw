import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/branding.dart';
import '../../core/state/session_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_fr.dart';
import '../../core/utils/friendly_error.dart';
import '../../core/utils/responsive_helper.dart';
import '../../core/utils/view_state.dart';
import '../../core/widgets/async_state_view.dart';
import '../../core/widgets/decorative_header_band.dart';
import '../../core/widgets/fill_gauge.dart';
import '../../core/widgets/trip_type_badge.dart';
import '../../data/models/enums.dart';
import '../../data/models/planning_entry.dart';
import '../../data/models/trip.dart';
import '../../data/repositories/planning_repository.dart';
import '../../data/repositories/trip_repository.dart';

/// Tableau de bord passager : prochain trajet, ce qu'il y a à faire, stats
/// rapides, puis accès aux 3 modes de réservation. Remplace l'ancien simple
/// sélecteur de mode par un vrai point d'entrée accueillant.
class PassengerDashboardScreen extends StatefulWidget {
  const PassengerDashboardScreen({super.key});

  @override
  State<PassengerDashboardScreen> createState() =>
      _PassengerDashboardScreenState();
}

class _PassengerDashboardScreenState extends State<PassengerDashboardScreen> {
  final _tripRepository = TripRepository();
  final _planningRepository = PlanningRepository();
  ViewState<_DashboardData> _state = const ViewState.loading();

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
      final aVenir = trips.where((t) => t.statut != TripStatus.termine).toList()
        ..sort((a, b) {
          final cmp = a.date.compareTo(b.date);
          if (cmp != 0) return cmp;
          return a.heureRamassageEstimee.compareTo(b.heureRamassageEstimee);
        });

      final planning = await _planningRepository.getPlanningForPassenger(
        passengerId,
      );
      final planningEntries = planning != null
          ? await _planningRepository.getEntries(planning.id)
          : const <PlanningEntry>[];

      setState(
        () => _state = ViewState.success(
          _DashboardData(
            prochainTrajet: aVenir.isEmpty ? null : aVenir.first,
            nombreAVenir: aVenir.length,
            nombreHistorique: trips.length - aVenir.length,
            aPlanningActif: planningEntries.any((e) => e.actif),
          ),
        ),
      );
    } catch (e) {
      setState(() => _state = ViewState.error(friendlyError(e)));
    }
  }

  String _libelle(Trip trip) => trip.mode == TripMode.interregions
      ? '${trip.villeDepart} → ${trip.villeArrivee}'
      : '${trip.adresseDepart} → ${trip.destination}';

  String _routeForTrip(Trip trip) {
    switch (trip.mode) {
      case TripMode.ponctuelle:
        return switch (trip.statut) {
          TripStatus.enAttente =>
            '/passager/home/ponctuelle/resultats/${trip.id}',
          TripStatus.confirme =>
            '/passager/home/ponctuelle-confirmation/${trip.id}',
          TripStatus.enRoute => '/passager/home/ponctuelle-suivi/${trip.id}',
          TripStatus.termine => '/passager/historique',
        };
      case TripMode.interregions:
        return trip.statut == TripStatus.enAttente
            ? '/passager/home/interregions/resultats/${trip.id}'
            : '/passager/home/interregions-confirmation/${trip.id}';
      case TripMode.mensuelle:
        return '/passager/home/mensuelle/mon-planning';
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<SessionProvider>().activeProfile;
    final padding = ResponsiveHelper.horizontalPadding(context);
    final prenom = profile?.nom.split(' ').first ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          Branding.appName,
          style: const TextStyle(
            color: AppColors.brown,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: AsyncStateView<_DashboardData>(
          state: _state,
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
                        'Voici ce qui vous attend',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (data.prochainTrajet != null) ...[
                        Text(
                          'Prochain trajet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        _ProchainTrajetCard(
                          trip: data.prochainTrajet!,
                          libelle: _libelle(data.prochainTrajet!),
                          onTap: () =>
                              context.go(_routeForTrip(data.prochainTrajet!)),
                        ),
                        const SizedBox(height: 20),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              icon: Icons.event_available_outlined,
                              label: 'À venir',
                              value: '${data.nombreAVenir}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatTile(
                              icon: Icons.history,
                              label: 'Historique',
                              value: '${data.nombreHistorique}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SavingsBanner(
                        onTap: () =>
                            context.go('/passager/home/mensuelle/mon-planning'),
                      ),
                      if (!data.aPlanningActif) ...[
                        const SizedBox(height: 16),
                        _ActionCard(
                          icon: Icons.event_repeat_outlined,
                          title: 'Créez votre planning mensuel',
                          subtitle:
                              'Pour vos trajets réguliers, sans tout ressaisir chaque jour.',
                          onTap: () =>
                              context.push('/passager/home/mensuelle/creer'),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        'Réserver un trajet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _ModeCard(
                        icon: Icons.today_outlined,
                        title: 'Ponctuelle',
                        subtitle: "Un trajet pour demain, réservé aujourd'hui",
                        color: AppColors.primary,
                        onTap: () => context.go('/passager/home/ponctuelle'),
                      ),
                      const SizedBox(height: 12),
                      _ModeCard(
                        icon: Icons.event_repeat_outlined,
                        title: 'Mensuelle',
                        subtitle:
                            'Un planning récurrent pour vos trajets réguliers',
                        color: AppColors.brown,
                        onTap: () =>
                            context.go('/passager/home/mensuelle/mon-planning'),
                      ),
                      const SizedBox(height: 12),
                      _ModeCard(
                        icon: Icons.alt_route_outlined,
                        title: 'Inter-régions',
                        subtitle: 'Voyagez entre villes en toute simplicité',
                        color: AppColors.success,
                        onTap: () => context.go('/passager/home/interregions'),
                      ),
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

class _SavingsBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _SavingsBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Économisez jusqu\'à 50%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Partagez vos trajets, réduisez vos coûts !',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/illustrations/minibus_savings.jpg',
                  width: 90,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardData {
  final Trip? prochainTrajet;
  final int nombreAVenir;
  final int nombreHistorique;
  final bool aPlanningActif;

  const _DashboardData({
    required this.prochainTrajet,
    required this.nombreAVenir,
    required this.nombreHistorique,
    required this.aPlanningActif,
  });
}

class _ProchainTrajetCard extends StatelessWidget {
  final Trip trip;
  final String libelle;
  final VoidCallback onTap;

  const _ProchainTrajetCard({
    required this.trip,
    required this.libelle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final confirme = trip.statut != TripStatus.enAttente;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TripTypeBadge(mode: trip.mode),
                  const SizedBox(width: 8),
                  Text(DateFr.shortDate(trip.date)),
                  const Spacer(),
                  Text(
                    trip.heureRamassageEstimee,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(libelle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              FillGaugeWidget(
                placesRemplies: trip.placesRemplies,
                placesTotal: trip.placesTotal,
                confirme: confirme,
              ),
            ],
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.sunAccent.withValues(alpha: 0.15),
      child: ListTile(
        leading: Icon(icon, color: AppColors.brown),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
