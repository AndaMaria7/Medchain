class HospitalModel {
  final String id;
  final String name;
  final String location;
  final double latitude;
  final double longitude;
  final int icuBeds;
  final int emergencyBeds;
  final int ventilators;
  final bool hasCardiacSurgery;
  final bool hasTraumaCenter;
  final int waitTime; // in minutes
  final double? distance; // in kilometers
  final int reputationScore;
  final DateTime lastUpdated;
  final String? phoneNumber;
  final String? address;

  const HospitalModel({
    required this.id,
    required this.name,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.icuBeds,
    required this.emergencyBeds,
    required this.ventilators,
    required this.hasCardiacSurgery,
    required this.hasTraumaCenter,
    required this.waitTime,
    this.distance,
    required this.reputationScore,
    required this.lastUpdated,
    this.phoneNumber,
    this.address,
  });

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    return HospitalModel(
      id: json['hospital_id'] ?? json['id'] ?? '',
      name: json['name'] ?? json['hospital_name'] ?? '',
      location: json['location_text'] ?? json['location'] ?? '',
      latitude: _parseDouble(json['location']?['lat'] ?? json['latitude'] ?? 0.0),
      longitude: _parseDouble(json['location']?['lng'] ?? json['longitude'] ?? 0.0),
      icuBeds: _parseInt(json['icu_beds_available'] ?? json['icuBeds'] ?? 0),
      emergencyBeds: _parseInt(json['emergency_beds_available'] ?? json['emergencyBeds'] ?? 0),
      ventilators: _parseInt(json['ventilators_available'] ?? json['ventilators'] ?? 0),
      hasCardiacSurgery: json['has_cardiac_surgery'] ?? json['hasCardiacSurgery'] ?? false,
      hasTraumaCenter: json['has_trauma_center'] ?? json['hasTraumaCenter'] ?? false,
      waitTime: _parseInt(json['average_wait_time_minutes'] ?? json['waitTime'] ?? 30),
      distance: json['distance_km'] != null ? _parseDouble(json['distance_km']) : null,
      reputationScore: _parseInt(json['reputation_score'] ?? json['reputationScore'] ?? 100),
      lastUpdated: _parseDateTime(json['last_updated'] ?? json['lastUpdated']),
      phoneNumber: json['phone_number'] ?? json['phoneNumber'],
      address: json['full_address'] ?? json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hospital_id': id,
      'name': name,
      'location_text': location,
      'location': {
        'lat': latitude,
        'lng': longitude,
      },
      'icu_beds_available': icuBeds,
      'emergency_beds_available': emergencyBeds,
      'ventilators_available': ventilators,
      'has_cardiac_surgery': hasCardiacSurgery,
      'has_trauma_center': hasTraumaCenter,
      'average_wait_time_minutes': waitTime,
      'distance_km': distance,
      'reputation_score': reputationScore,
      'last_updated': lastUpdated.toIso8601String(),
      'phone_number': phoneNumber,
      'full_address': address,
    };
  }

  HospitalModel copyWith({
    String? id,
    String? name,
    String? location,
    double? latitude,
    double? longitude,
    int? icuBeds,
    int? emergencyBeds,
    int? ventilators,
    bool? hasCardiacSurgery,
    bool? hasTraumaCenter,
    int? waitTime,
    double? distance,
    int? reputationScore,
    DateTime? lastUpdated,
    String? phoneNumber,
    String? address,
  }) {
    return HospitalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      icuBeds: icuBeds ?? this.icuBeds,
      emergencyBeds: emergencyBeds ?? this.emergencyBeds,
      ventilators: ventilators ?? this.ventilators,
      hasCardiacSurgery: hasCardiacSurgery ?? this.hasCardiacSurgery,
      hasTraumaCenter: hasTraumaCenter ?? this.hasTraumaCenter,
      waitTime: waitTime ?? this.waitTime,
      distance: distance ?? this.distance,
      reputationScore: reputationScore ?? this.reputationScore,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
    );
  }

  // Helper methods
  bool get hasAvailableBeds => icuBeds > 0 || emergencyBeds > 0;
  
  String get capacityStatus {
    if (icuBeds == 0 && emergencyBeds == 0) return 'Complet ocupat';
    if (icuBeds > 5 || emergencyBeds > 10) return 'Disponibilitate mare';
    if (icuBeds > 2 || emergencyBeds > 5) return 'Disponibilitate medie';
    return 'Disponibilitate limitată';
  }
  
  String get waitTimeStatus {
    if (waitTime <= 15) return 'Timp scurt de așteptare';
    if (waitTime <= 30) return 'Timp mediu de așteptare';
    return 'Timp lung de așteptare';
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
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
    return 'HospitalModel(id: $id, name: $name, icuBeds: $icuBeds, emergencyBeds: $emergencyBeds, distance: $distance)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HospitalModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}