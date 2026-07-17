import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/constants/branding.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/state/session_provider.dart';
import 'core/theme/app_theme.dart';
import 'data/models/enums.dart';

class CovoiturageApp extends StatefulWidget {
  const CovoiturageApp({super.key});

  @override
  State<CovoiturageApp> createState() => _CovoiturageAppState();
}

class _CovoiturageAppState extends State<CovoiturageApp> {
  late final SessionProvider _session;
  late GoRouter _router;
  UserRole? _lastRole;

  @override
  void initState() {
    super.initState();
    _session = SessionProvider();
    _router = buildRouter(_session);
    _session.addListener(_onSessionChanged);
    NotificationService.instance.init();
  }

  /// Une connexion ou un switch de rôle (démo) reconstruit le routeur pour
  /// repartir sur une pile de navigation vierge — jamais de retour possible
  /// sur un écran encore poussé côté de l'autre rôle.
  void _onSessionChanged() {
    final role = _session.activeProfile?.role;
    if (role != null && role != _lastRole) {
      setState(() => _router = buildRouter(_session));
    }
    _lastRole = role;
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _session,
      child: MaterialApp.router(
        key: ValueKey(_router),
        title: Branding.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
