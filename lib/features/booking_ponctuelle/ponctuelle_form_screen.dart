import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/locations.dart';
import '../../core/state/session_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/friendly_error.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/trip_repository.dart';

class PonctuelleFormScreen extends StatefulWidget {
  const PonctuelleFormScreen({super.key});

  @override
  State<PonctuelleFormScreen> createState() => _PonctuelleFormScreenState();
}

class _PonctuelleFormScreenState extends State<PonctuelleFormScreen> {
  final _tripRepository = TripRepository();

  String? _adresseDepart;
  String? _destination;
  String? _heureArrivee;
  bool _submitting = false;
  String? _errorAdresse;
  String? _errorDestination;
  String? _errorHeure;

  Future<void> _pickHeure() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _heureArrivee =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        _errorHeure = null;
      });
    }
  }

  bool _validate() {
    setState(() {
      _errorAdresse = _adresseDepart == null
          ? 'Choisissez une adresse de départ.'
          : null;
      _errorDestination = _destination == null
          ? 'Choisissez une destination.'
          : null;
      _errorHeure = _heureArrivee == null
          ? "Choisissez une heure d'arrivée."
          : null;
    });
    return _errorAdresse == null && _errorDestination == null && _errorHeure == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _submitting = true);
    final passengerId = context.read<SessionProvider>().activeProfile!.id;
    final demain = DateTime.now().add(const Duration(days: 1));

    try {
      final trip = await _tripRepository.findOrCreateMatch(
        passengerId: passengerId,
        mode: TripMode.ponctuelle,
        adresseDepart: _adresseDepart,
        destination: _destination,
        heureArriveeSouhaitee: _heureArrivee!,
        date: demain,
      );
      if (!mounted) return;
      context.go('/passager/home/ponctuelle/resultats/${trip.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réservation ponctuelle')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.today_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Départ demain',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Un chauffeur passera vous prendre selon vos horaires',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _adresseDepart,
                      decoration: InputDecoration(
                        labelText: 'Adresse de départ',
                        errorText: _errorAdresse,
                        prefixIcon: const Icon(Icons.trip_origin),
                      ),
                      items: AppLocations.dakarNeighborhoods
                          .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                          .toList(),
                      onChanged: (v) => setState(() => _adresseDepart = v),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _pickHeure,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Heure d'arrivée souhaitée",
                          errorText: _errorHeure,
                          prefixIcon: const Icon(Icons.access_time),
                        ),
                        child: Text(_heureArrivee ?? 'Choisir une heure'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _destination,
                      decoration: InputDecoration(
                        labelText: 'Destination',
                        errorText: _errorDestination,
                        prefixIcon: const Icon(Icons.location_on_outlined),
                      ),
                      items: AppLocations.dakarNeighborhoods
                          .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                          .toList(),
                      onChanged: (v) => setState(() => _destination = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search),
              label: const Text('Rechercher un trajet'),
            ),
          ],
        ),
      ),
    );
  }
}
