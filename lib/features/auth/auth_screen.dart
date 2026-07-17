import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/branding.dart';
import '../../core/state/session_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_helper.dart';
import '../../core/utils/view_state.dart';
import '../../data/models/enums.dart';
import '../../data/models/user_profile.dart';

/// Écran de connexion — reprend l'illustration hero de la planche de design
/// (Kirikou + 4x4, baobabs, skyline). Auth mockée : pas de vrai backend,
/// juste un choix explicite de rôle pour démontrer les deux côtés en démo.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _loading = false;

  Future<void> _login(UserRole role) async {
    setState(() => _loading = true);
    final session = context.read<SessionProvider>();
    await session.loginAs(role);
    if (!mounted) return;
    setState(() => _loading = false);

    switch (session.state) {
      case ViewStateSuccess<UserProfile>():
        context.go(
          role == UserRole.passager ? '/passager/home' : '/chauffeur/dashboard',
        );
      case ViewStateError<UserProfile>(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.horizontalPadding(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: 20),
            child: Column(
              children: [
                Text(
                  Branding.appName,
                  style: GoogleFonts.baloo2(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brown,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  Branding.slogan,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/illustrations/hero_splash.jpg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () => _login(UserRole.passager),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Se connecter comme passager'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _loading
                        ? null
                        : () => _login(UserRole.chauffeur),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brown,
                      side: const BorderSide(color: AppColors.brown),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Se connecter comme chauffeur'),
                  ),
                ),
                const SizedBox(height: 36),
                Row(
                  children: const [
                    Expanded(
                      child: _ValueProp(
                        icon: Icons.savings_outlined,
                        title: 'Économique',
                        subtitle: 'Payez moins, voyagez plus',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _ValueProp(
                        icon: Icons.bolt_outlined,
                        title: 'Pratique',
                        subtitle: 'Planifiez, réservez, partez serein',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    Expanded(
                      child: _ValueProp(
                        icon: Icons.verified_user_outlined,
                        title: 'Sécurisé',
                        subtitle: 'Chauffeurs vérifiés, trajets suivis',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _ValueProp(
                        icon: Icons.eco_outlined,
                        title: 'Écologique',
                        subtitle: 'Moins de voitures, plus d\'impact positif',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ValueProp extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ValueProp({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
