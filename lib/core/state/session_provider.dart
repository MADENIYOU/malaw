import 'package:flutter/foundation.dart';

import '../../data/models/enums.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/profile_repository.dart';
import '../utils/friendly_error.dart';
import '../utils/view_state.dart';

/// État de session mocké : pas de vrai backend d'auth, juste un profil actif
/// (passager ou chauffeur) sélectionné à la connexion, avec un raccourci de
/// bascule de rôle pour pouvoir démontrer les deux côtés en live.
class SessionProvider extends ChangeNotifier {
  SessionProvider({ProfileRepository? profileRepository})
    : _profileRepository = profileRepository ?? ProfileRepository();

  final ProfileRepository _profileRepository;

  ViewState<UserProfile> _state = const ViewState.loading();
  ViewState<UserProfile> get state => _state;

  UserProfile? get activeProfile => switch (_state) {
    ViewStateSuccess<UserProfile>(:final data) => data,
    _ => null,
  };

  bool get isLoggedIn => activeProfile != null;

  Future<void> loginAs(UserRole role) async {
    _state = const ViewState.loading();
    notifyListeners();
    try {
      final profiles = await _profileRepository.getProfilesByRole(role);
      _state = profiles.isEmpty
          ? const ViewState.empty()
          : ViewState.success(profiles.first);
    } catch (e) {
      _state = ViewState.error(friendlyError(e));
    }
    notifyListeners();
  }

  Future<void> switchRole() async {
    final current = activeProfile;
    if (current == null) return;
    final newRole = current.role == UserRole.passager
        ? UserRole.chauffeur
        : UserRole.passager;
    await loginAs(newRole);
  }

  void logout() {
    _state = const ViewState.loading();
    notifyListeners();
  }
}
