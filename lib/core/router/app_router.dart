import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/enums.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/booking_interregions/interregions_confirmation_screen.dart';
import '../../features/booking_interregions/interregions_form_screen.dart';
import '../../features/booking_interregions/interregions_resultats_screen.dart';
import '../../features/booking_mensuelle/mensuelle_creer_screen.dart';
import '../../features/booking_mensuelle/mensuelle_draft_entry.dart';
import '../../features/booking_mensuelle/mensuelle_recap_screen.dart';
import '../../features/booking_mensuelle/mon_planning_screen.dart';
import '../../features/booking_ponctuelle/ponctuelle_confirmation_screen.dart';
import '../../features/booking_ponctuelle/ponctuelle_form_screen.dart';
import '../../features/booking_ponctuelle/ponctuelle_resultats_screen.dart';
import '../../features/driver/driver_dashboard_screen.dart';
import '../../features/driver/driver_historique_screen.dart';
import '../../features/driver/driver_profil_screen.dart';
import '../../features/driver/driver_trip_detail_screen.dart';
import '../../features/driver/driver_trip_in_progress_screen.dart';
import '../../features/history_profile/historique_screen.dart';
import '../../features/history_profile/profil_screen.dart';
import '../../features/home/passenger_dashboard_screen.dart';
import '../../features/trip_tracking/trip_tracking_screen.dart';
import '../state/session_provider.dart';
import '../widgets/bottom_nav_shell.dart';

const _passagerNavItems = [
  BottomNavigationBarItem(
    icon: Icon(Icons.home_outlined),
    activeIcon: Icon(Icons.home),
    label: 'Accueil',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.history_outlined),
    activeIcon: Icon(Icons.history),
    label: 'Historique',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.person_outline),
    activeIcon: Icon(Icons.person),
    label: 'Profil',
  ),
];

const _chauffeurNavItems = [
  BottomNavigationBarItem(
    icon: Icon(Icons.dashboard_outlined),
    activeIcon: Icon(Icons.dashboard),
    label: 'Trajets',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.history_outlined),
    activeIcon: Icon(Icons.history),
    label: 'Historique',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.person_outline),
    activeIcon: Icon(Icons.person),
    label: 'Profil',
  ),
];

GoRouter buildRouter(SessionProvider session) {
  return GoRouter(
    initialLocation: '/auth',
    refreshListenable: session,
    redirect: (context, state) {
      final profile = session.activeProfile;
      final onAuth = state.matchedLocation == '/auth';

      if (profile == null) return onAuth ? null : '/auth';

      final home = profile.role == UserRole.passager
          ? '/passager/home'
          : '/chauffeur/dashboard';
      if (onAuth) return home;

      final onPassagerRoutes = state.matchedLocation.startsWith('/passager');
      final onChauffeurRoutes = state.matchedLocation.startsWith('/chauffeur');
      if (profile.role == UserRole.passager && onChauffeurRoutes) return home;
      if (profile.role == UserRole.chauffeur && onPassagerRoutes) return home;
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => BottomNavShell(
          navigationShell: navigationShell,
          items: _passagerNavItems,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/passager/home',
                builder: (context, state) => const PassengerDashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'ponctuelle',
                    builder: (context, state) => const PonctuelleFormScreen(),
                    routes: [
                      GoRoute(
                        path: 'resultats/:tripId',
                        builder: (context, state) => PonctuelleResultatsScreen(
                          tripId: state.pathParameters['tripId']!,
                        ),
                      ),
                    ],
                  ),
                  // Confirmation/suivi sont volontairement des routes sœurs
                  // (pas nichées sous ponctuelle) : y naviguer avec go()
                  // réinitialise la pile à [Accueil, écran], impossible de
                  // "revenir" dans un formulaire déjà réservé.
                  GoRoute(
                    path: 'ponctuelle-confirmation/:tripId',
                    builder: (context, state) => PonctuelleConfirmationScreen(
                      tripId: state.pathParameters['tripId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'ponctuelle-suivi/:tripId',
                    builder: (context, state) => TripTrackingScreen(
                      tripId: state.pathParameters['tripId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'mensuelle/creer',
                    builder: (context, state) => const MensuelleCreerScreen(),
                  ),
                  GoRoute(
                    path: 'mensuelle/recap',
                    builder: (context, state) => MensuelleRecapScreen(
                      draftEntries:
                          state.extra as List<MensuelleDraftEntry>? ??
                          const [],
                    ),
                  ),
                  GoRoute(
                    path: 'mensuelle/mon-planning',
                    builder: (context, state) => const MonPlanningScreen(),
                  ),
                  GoRoute(
                    path: 'interregions',
                    builder: (context, state) => const InterregionsFormScreen(),
                    routes: [
                      GoRoute(
                        path: 'resultats/:tripId',
                        builder: (context, state) => InterregionsResultatsScreen(
                          tripId: state.pathParameters['tripId']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'interregions-confirmation/:tripId',
                    builder: (context, state) => InterregionsConfirmationScreen(
                      tripId: state.pathParameters['tripId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/passager/historique',
                builder: (context, state) => const HistoriqueScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/passager/profil',
                builder: (context, state) => const ProfilScreen(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => BottomNavShell(
          navigationShell: navigationShell,
          items: _chauffeurNavItems,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chauffeur/dashboard',
                builder: (context, state) => const DriverDashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'trajet/:tripId',
                    builder: (context, state) => DriverTripDetailScreen(
                      tripId: state.pathParameters['tripId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'en-cours',
                        builder: (context, state) => DriverTripInProgressScreen(
                          tripId: state.pathParameters['tripId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chauffeur/historique',
                builder: (context, state) => const DriverHistoriqueScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chauffeur/profil',
                builder: (context, state) => const DriverProfilScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
