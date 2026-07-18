import 'package:flutter/material.dart';

import '../services/location_service.dart';
import '../theme/app_colors.dart';
import '../utils/friendly_error.dart';

/// Bouton « Ma position actuelle » : géolocalise l'utilisateur, ramène le
/// quartier connu le plus proche et le renvoie via [onLocated]. Gère son
/// propre état de chargement et affiche les erreurs en SnackBar (message
/// convivial). À placer sous un champ « Adresse de départ ».
class UseMyLocationButton extends StatefulWidget {
  final ValueChanged<String> onLocated;

  const UseMyLocationButton({super.key, required this.onLocated});

  @override
  State<UseMyLocationButton> createState() => _UseMyLocationButtonState();
}

class _UseMyLocationButtonState extends State<UseMyLocationButton> {
  bool _loading = false;

  Future<void> _locate() async {
    setState(() => _loading = true);
    try {
      final nearest = await LocationService.instance.nearestNeighborhood();
      if (!mounted) return;
      widget.onLocated(nearest.name);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Départ défini sur « ${nearest.name} » '
            '(${(nearest.distanceMeters / 1000).toStringAsFixed(1)} km de vous)',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: _loading ? null : _locate,
        icon: _loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location, size: 18),
        label: Text(_loading ? 'Localisation…' : 'Ma position actuelle'),
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
    );
  }
}
