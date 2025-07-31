class HospitalModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final String? phoneNumber;
  final List<String>? specialties;
  final int? capacity;
  final int? availableBeds;
  final Map<String, dynamic>? additionalData;

  const HospitalModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.phoneNumber,
    this.specialties,
    this.capacity,
    this.availableBeds,
    this.additionalData,
  });

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    List<String> parseSpecialties(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return [];
    }

    return HospitalModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Hospital',
      latitude: _parseDouble(json['location']?['lat'] ?? json['latitude'] ?? 0.0),
      longitude: _parseDouble(json['location']?['lng'] ?? json['longitude'] ?? 0.0),
      address: json['address'] ?? json['location_address'] ?? 'Unknown Address',
      phoneNumber: json['phoneNumber'] ?? json['phone'],
      specialties: json['specialties'] != null ? parseSpecialties(json['specialties']) : null,
      capacity: json['capacity'] is int ? json['capacity'] : null,
      availableBeds: json['availableBeds'] is int ? json['availableBeds'] : null,
      additionalData: json['additionalData'],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': {
        'lat': latitude,
        'lng': longitude,
      },
      'address': address,
      'phoneNumber': phoneNumber,
      'specialties': specialties,
      'capacity': capacity,
      'availableBeds': availableBeds,
      'additionalData': additionalData,
    };
  }
}
