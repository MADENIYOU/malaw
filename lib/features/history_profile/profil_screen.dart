import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/session_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/decorative_header_band.dart';

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<SessionProvider>().activeProfile;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        child: ListView(
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
                      backgroundColor: AppColors.primary,
                      child: Text(
                        profile?.initials ?? '?',
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
                      profile?.nom ?? '',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Center(
                    child: Text(
                      profile?.telephone ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.swap_horiz,
                        color: AppColors.primary,
                      ),
                      title: const Text('Basculer en mode chauffeur'),
                      subtitle: const Text(
                        'Pour la démo : voir l\'app côté chauffeur',
                      ),
                      onTap: () => context.read<SessionProvider>().switchRole(),
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
    );
  }
}
