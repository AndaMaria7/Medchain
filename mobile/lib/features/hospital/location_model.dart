import 'dart:math';

class LocationModel {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? country;
  final double? accuracy;
  final DateTime timestamp;

  const LocationModel({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.country,
    this.accuracy,
    required this.timestamp,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: _parseDouble(json['lat'] ?? json['latitude'] ?? 0.0),
      longitude: _parseDouble(json['lng'] ?? json['longitude'] ?? 0.0),
      address: json['address'],
      city: json['city'],
      country: json['country'],
      accuracy: json['accuracy'] != null ? _parseDouble(json['accuracy']) : null,
      timestamp: _parseDateTime(json['timestamp']),
    );
  }

  factory LocationModel.fromPosition(dynamic position, {String? address}) {
    return LocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
      address: address,
      accuracy: position.accuracy,
      timestamp: position.timestamp ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': latitude,
      'lng': longitude,
      'address': address,
      'city': city,
      'country': country,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  LocationModel copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? country,
    double? accuracy,
    DateTime? timestamp,
  }) {
    return LocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  // Helper methods
  String get coordinatesString => '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  
  String get displayAddress => address ?? coordinatesString;

  double distanceTo(LocationModel other) {
    return _calculateDistance(latitude, longitude, other.latitude, other.longitude);
  }

  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371.0; // Earth's radius in kilometers

    // Convert differences and latitudes to radians
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    final double radLat1 = _degreesToRadians(lat1);
    final double radLat2 = _degreesToRadians(lat2);

    // Haversine formula
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(radLat1) * cos(radLat2) *
            sin(dLon / 2) * sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c; // Distance in kilometers
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (3.141592653589793 / 180);
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  @override
  String toString() {
    return 'LocationModel(lat: $latitude, lng: $longitude, address: $address)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationModel &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude);
}