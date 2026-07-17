import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/session_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/friendly_error.dart';
import '../../core/utils/view_state.dart';
import '../../core/widgets/async_state_view.dart';
import '../../core/widgets/decorative_header_band.dart';
import '../../data/models/driver.dart';
import '../../data/repositories/driver_repository.dart';

class DriverProfilScreen extends StatefulWidget {
  const DriverProfilScreen({super.key});

  @override
  State<DriverProfilScreen> createState() => _DriverProfilScreenState();
}

class _DriverProfilScreenState extends State<DriverProfilScreen> {
  final _driverRepository = DriverRepository();
  ViewState<Driver> _state = const ViewState.loading();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const ViewState.loading());
    try {
      final driverId = context.read<SessionProvider>().activeProfile!.id;
      final driver = await _driverRepository.getDriverById(driverId);
      setState(
        () => _state = driver == null
            ? const ViewState.empty()
            : ViewState.success(driver),
      );
    } catch (e) {
      setState(() => _state = ViewState.error(friendlyError(e)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil chauffeur')),
      body: SafeArea(
        child: AsyncStateView<Driver>(
          state: _state,
          onRetry: _load,
          builder: (context, driver) => ListView(
            padding: EdgeInsets.zero,
            children: [
              const DecorativeHeaderBand(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.brown,
                        child: Text(
                          driver.nom.isNotEmpty
                              ? driver.nom[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        driver.nom,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Center(
                      child: Text(
                        driver.vehicule,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppColors.sunAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(driver.note.toStringAsFixed(1)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.swap_horiz,
                          color: AppColors.primary,
                        ),
                        title: const Text('Basculer en mode passager'),
                        subtitle: const Text(
                          'Pour la démo : voir l\'app côté passager',
                        ),
                        onTap: () =>
                            context.read<SessionProvider>().switchRole(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.logout,
                          color: AppColors.textSecondary,
                        ),
                        title: const Text('Se déconnecter'),
                        onTap: () => context.read<SessionProvider>().logout(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
