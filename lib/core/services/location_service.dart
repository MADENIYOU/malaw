import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show PlatformException;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../constants/location_coordinates.dart';
import '../utils/retry_util.dart';

/// Résultat d'une localisation : le quartier connu le plus proche de la
/// position réelle de l'utilisateur, plus la distance à vol d'oiseau (m).
class NearestLocation {
  final String name;
  final double distanceMeters;

  const NearestLocation({required this.name, required this.distanceMeters});
}

/// Géolocalisation navigateur/appareil, ramenée au modèle de l'app : comme
/// on stocke des noms de quartiers (pas de géocodage réel), on renvoie le
/// quartier de Dakar le plus proche des coordonnées GPS obtenues.
///
/// Toutes les erreurs sont converties en [NonRetryableException] avec un
/// message lisible — inutile de retenter une permission refusée, et le
/// message remonte tel quel via `friendlyError`.
class LocationService {
  LocationService._();

  static final LocationService instance = LocationService._();

  Future<NearestLocation> nearestNeighborhood() async {
    // 1) Permission.
    //
    // Sur le WEB, on NE fait PAS le check/request de geolocator : la
    // Permissions API renvoie souvent `denied` pour l'état « à demander », ce
    // qui ferait échouer avant même d'afficher la popup. On appelle donc
    // directement `getCurrentPosition`, qui déclenche lui-même la demande
    // d'autorisation native du navigateur.
    //
    // Sur MOBILE/DESKTOP natif, on demande explicitement la permission.
    if (!kIsWeb) {
      LocationPermission permission;
      try {
        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
      } catch (e) {
        throw NonRetryableException(
          'Impossible d\'accéder à la localisation sur cet appareil.',
        );
      }

      if (permission == LocationPermission.denied) {
        throw NonRetryableException(
          'Autorisez l\'accès à votre position pour utiliser cette fonction.',
        );
      }
      if (permission == LocationPermission.deniedForever) {
        throw NonRetryableException(
          'Accès à la position bloqué. Autorisez-le dans les réglages, '
          'puis réessayez.',
        );
      }
    }

    // 2) Position — sur le web c'est aussi ce qui déclenche la popup du
    // navigateur ; on gère chaque échec typé avec un message dédié.
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );
    } on LocationServiceDisabledException {
      throw NonRetryableException(
        'La localisation est désactivée. Activez le GPS puis réessayez.',
      );
    } on PermissionDeniedException {
      throw NonRetryableException(
        'Autorisez l\'accès à votre position pour utiliser cette fonction.',
      );
    } on TimeoutException {
      throw NonRetryableException(
        'La localisation prend trop de temps. Réessayez en extérieur.',
      );
    } on PositionUpdateException {
      // Web (code 2) / natif : le système n'arrive pas à déterminer la
      // position (pas de GPS, service de localisation défaillant, appareil en
      // intérieur...). Rien à voir avec la permission.
      throw NonRetryableException(
        'Position introuvable pour le moment. Vérifiez que la localisation '
        'est activée et réessayez, de préférence en extérieur.',
      );
    } on PlatformException catch (e) {
      throw NonRetryableException(
        'Localisation indisponible${e.message != null ? ' : ${e.message}' : ''}.',
      );
    } catch (e) {
      // Cas non prévu : on expose le message réel (non minifié) pour
      // diagnostiquer — surtout utile en build web release.
      throw NonRetryableException('Localisation impossible : $e. Réessayez.');
    }

    return _snapToNearest(position.latitude, position.longitude);
  }

  NearestLocation _snapToNearest(double lat, double lng) {
    String? bestName;
    double bestDistance = double.infinity;

    LocationCoordinates.dakarNeighborhoods.forEach((name, LatLng coord) {
      final d = Geolocator.distanceBetween(
        lat,
        lng,
        coord.latitude,
        coord.longitude,
      );
      if (d < bestDistance) {
        bestDistance = d;
        bestName = name;
      }
    });

    if (bestName == null) {
      throw NonRetryableException('Aucun quartier connu à proximité.');
    }
    return NearestLocation(name: bestName!, distanceMeters: bestDistance);
  }
}
