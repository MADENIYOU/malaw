import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Coordonnées approximatives des lieux mockés, pour afficher une vraie
/// carte Google Maps (pas de géocodage réel, juste des positions plausibles).
class LocationCoordinates {
  LocationCoordinates._();

  static const Map<String, LatLng> dakarNeighborhoods = {
    'Ouakam': LatLng(14.7167, -17.4833),
    'Plateau': LatLng(14.6708, -17.4313),
    'Almadies': LatLng(14.7447, -17.5245),
    'Ngor': LatLng(14.7461, -17.5171),
    'Yoff': LatLng(14.7500, -17.4833),
    'Mermoz': LatLng(14.7050, -17.4700),
    'Sacré-Cœur': LatLng(14.7108, -17.4611),
    'Point E': LatLng(14.6928, -17.4478),
    'Fann': LatLng(14.6847, -17.4553),
    'Liberté 6': LatLng(14.7239, -17.4600),
    'Grand Yoff': LatLng(14.7333, -17.4500),
    'Parcelles Assainies': LatLng(14.7550, -17.4390),
    'Ouest Foire': LatLng(14.7450, -17.4700),
    'Hann': LatLng(14.7167, -17.4167),
    'Médina': LatLng(14.6797, -17.4436),
  };

  static const Map<String, LatLng> interRegionCities = {
    'Dakar': LatLng(14.6928, -17.4467),
    'Thiès': LatLng(14.7910, -16.9359),
    'Mbour': LatLng(14.4198, -16.9645),
    'Saint-Louis': LatLng(16.0179, -16.4896),
    'Kaolack': LatLng(14.1652, -16.0726),
    'Ziguinchor': LatLng(12.5556, -16.2719),
    'Touba': LatLng(14.8667, -15.8833),
    'Diourbel': LatLng(14.6522, -16.2317),
  };

  static LatLng forName(String name) =>
      dakarNeighborhoods[name] ?? interRegionCities[name] ?? const LatLng(14.6928, -17.4467);
}
