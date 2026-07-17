import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/locations.dart';
import '../../core/state/session_provider.dart';
import '../../core/utils/friendly_error.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/trip_repository.dart';

class InterregionsFormScreen extends StatefulWidget {
  const InterregionsFormScreen({super.key});

  @override
  State<InterregionsFormScreen> createState() =>
      _InterregionsFormScreenState();
}

class _InterregionsFormScreenState extends State<InterregionsFormScreen> {
  final _tripRepository = TripRepository();

  String? _villeDepart;
  String? _villeArrivee;
  String? _heureArrivee;
  bool _submitting = false;
  String? _errorDepart;
  String? _errorArrivee;
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
      _errorDepart = _villeDepart == null ? 'Choisissez une ville de départ.' : null;
      _errorArrivee = _villeArrivee == null
          ? 'Choisissez une ville d\'arrivée.'
          : _villeArrivee == _villeDepart
              ? 'La ville d\'arrivée doit différer du départ.'
              : null;
      _errorHeure = _heureArrivee == null
          ? "Choisissez une heure d'arrivée."
          : null;
    });
    return _errorDepart == null && _errorArrivee == null && _errorHeure == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _submitting = true);
    final passengerId = context.read<SessionProvider>().activeProfile!.id;
    final demain = DateTime.now().add(const Duration(days: 1));

    try {
      final trip = await _tripRepository.findOrCreateMatch(
        passengerId: passengerId,
        mode: TripMode.interregions,
        villeDepart: _villeDepart,
        villeArrivee: _villeArrivee,
        heureArriveeSouhaitee: _heureArrivee!,
        date: demain,
      );
      if (!mounted) return;
      context.go('/passager/home/interregions/resultats/${trip.id}');
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
      appBar: AppBar(title: const Text('Inter-régions')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.asset(
                    'assets/illustrations/interregional_bus.jpg',
                    width: double.infinity,
                    height: 110,
                    fit: BoxFit.cover,
                  ),
                  Positioned.fill(
                    child: Container(color: Colors.black.withValues(alpha: 0.25)),
                  ),
                  Positioned(
                    left: 16,
                    top: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Voyagez à travers le Sénégal',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Réservez votre place à l\'avance',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _villeDepart,
                      decoration: InputDecoration(
                        labelText: 'Ville de départ',
                        errorText: _errorDepart,
                        prefixIcon: const Icon(Icons.trip_origin),
                      ),
                      items: AppLocations.interRegionCities
                          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                          .toList(),
                      onChanged: (v) => setState(() => _villeDepart = v),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _villeArrivee,
                      decoration: InputDecoration(
                        labelText: "Ville d'arrivée",
                        errorText: _errorArrivee,
                        prefixIcon: const Icon(Icons.location_on_outlined),
                      ),
                      items: AppLocations.interRegionCities
                          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                          .toList(),
                      onChanged: (v) => setState(() => _villeArrivee = v),
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
