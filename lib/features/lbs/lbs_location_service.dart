import 'dart:math';
import 'package:geolocator/geolocator.dart';

class AgriculturalPoint {
  final String id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final String address;
  final String description;

  const AgriculturalPoint({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.description,
  });
}

class LocationTargetResult {
  final AgriculturalPoint point;
  final double distanceKm;
  final double bearingDegrees;

  const LocationTargetResult({
    required this.point,
    required this.distanceKm,
    required this.bearingDegrees,
  });
}

class LbsLocationService {
  static final LbsLocationService _instance = LbsLocationService._internal();
  factory LbsLocationService() => _instance;
  LbsLocationService._internal();

  // Predefined Indonesian & Regional Agricultural Hubs / Markets
  static const List<AgriculturalPoint> defaultHubs = [
    AgriculturalPoint(
      id: 'hub-1',
      name: 'Pasar Induk Beras Cipinang',
      category: 'Wholesale Grain Market',
      latitude: -6.216345,
      longitude: 106.887968,
      address: 'Pulo Gadung, Jakarta Timur',
      description: 'The largest central rice trading and distribution hub in Indonesia.',
    ),
    AgriculturalPoint(
      id: 'hub-2',
      name: 'Pasar Induk Kramat Jati',
      category: 'Fresh Produce Market',
      latitude: -6.277832,
      longitude: 106.871034,
      address: 'Kramat Jati, Jakarta Timur',
      description: 'Major central market for fruits, vegetables, and horticulture crops.',
    ),
    AgriculturalPoint(
      id: 'hub-3',
      name: 'Balai Besar Penelitian Tanaman Padi (BB Padi)',
      category: 'Agro Research & Seeds',
      latitude: -6.376123,
      longitude: 107.653412,
      address: 'Sukamandi, Subang, Jawa Barat',
      description: 'National rice research center developing high-yield resilient crop seeds.',
    ),
    AgriculturalPoint(
      id: 'hub-4',
      name: 'Agro Wisata Kebun Teh Wonosari',
      category: 'Plantation Center',
      latitude: -7.828342,
      longitude: 112.637123,
      address: 'Singosari, Malang, Jawa Timur',
      description: 'Large tea and plantation processing center in East Java.',
    ),
    AgriculturalPoint(
      id: 'hub-5',
      name: 'Sentra Hortikultura Lembang',
      category: 'Smart Greenhouse Farming',
      latitude: -6.818451,
      longitude: 107.618934,
      address: 'Lembang, Bandung Barat',
      description: 'Modern hydroponics and organic vegetable hub in West Java highlands.',
    ),
  ];

  // Default fallback position (Monas, Jakarta)
  static final Position fallbackPosition = Position(
    latitude: -6.175392,
    longitude: 106.827153,
    timestamp: DateTime.now(),
    accuracy: 5.0,
    altitude: 10.0,
    heading: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
    altitudeAccuracy: 0.0,
    headingAccuracy: 0.0,
  );

  /// Determine current position or fallback safely without crashing
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return fallbackPosition;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return fallbackPosition;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return fallbackPosition;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 4),
      );
    } catch (e) {
      return fallbackPosition;
    }
  }

  /// Calculates Haversine distance in Kilometers between two coordinates
  static double calculateDistanceKm({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    const earthRadiusKm = 6371.0;
    final dLat = _deg2rad(endLat - startLat);
    final dLon = _deg2rad(endLng - startLng);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(startLat)) * cos(_deg2rad(endLat)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Calculates initial bearing in degrees (0 - 360)
  static double calculateBearing({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    final lat1 = _deg2rad(startLat);
    final lat2 = _deg2rad(endLat);
    final dLon = _deg2rad(endLng - startLng);

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    final brng = atan2(y, x);
    return (_rad2deg(brng) + 360.0) % 360.0;
  }

  /// Evaluates nearby agricultural centers sorted by distance
  List<LocationTargetResult> getSortedNearbyHubs({
    required double currentLat,
    required double currentLng,
    List<AgriculturalPoint>? hubs,
  }) {
    final list = hubs ?? defaultHubs;
    final results = list.map((point) {
      final distance = calculateDistanceKm(
        startLat: currentLat,
        startLng: currentLng,
        endLat: point.latitude,
        endLng: point.longitude,
      );
      final bearing = calculateBearing(
        startLat: currentLat,
        startLng: currentLng,
        endLat: point.latitude,
        endLng: point.longitude,
      );
      return LocationTargetResult(point: point, distanceKm: distance, bearingDegrees: bearing);
    }).toList();

    results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return results;
  }

  static double _deg2rad(double deg) => deg * (pi / 180.0);
  static double _rad2deg(double rad) => rad * (180.0 / pi);
}
