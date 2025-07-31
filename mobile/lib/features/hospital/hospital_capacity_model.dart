class HospitalCapacityModel {
  final int icuBeds;
  final int emergencyBeds;
  final int ventilators;
  final DateTime lastUpdated;
  final String? txHash;
  final bool isVerified;
  final Map<String, dynamic>? additionalCapacity;

  const HospitalCapacityModel({
    required this.icuBeds,
    required this.emergencyBeds,
    required this.ventilators,
    required this.lastUpdated,
    this.txHash,
    this.isVerified = false,
    this.additionalCapacity,
  });

  factory HospitalCapacityModel.fromJson(Map<String, dynamic> json) {
    return HospitalCapacityModel(
      icuBeds: _parseInt(json['icu_beds'] ?? json['icuBeds'] ?? 0),
      emergencyBeds: _parseInt(json['emergency_beds'] ?? json['emergencyBeds'] ?? 0),
      ventilators: _parseInt(json['ventilators'] ?? 0),
      lastUpdated: _parseDateTime(json['last_updated'] ?? json['lastUpdated']),
      txHash: json['tx_hash'] ?? json['txHash'],
      isVerified: json['is_verified'] ?? json['isVerified'] ?? false,
      additionalCapacity: json['additional_capacity'] ?? json['additionalCapacity'],
    );
  }

  factory HospitalCapacityModel.fromBlockchain(Map<String, dynamic> blockchainData) {
    return HospitalCapacityModel(
      icuBeds: _parseInt(blockchainData['icuBeds'] ?? 0),
      emergencyBeds: _parseInt(blockchainData['emergencyBeds'] ?? 0),
      ventilators: _parseInt(blockchainData['ventilators'] ?? 0),
      lastUpdated: _parseDateTime(blockchainData['lastUpdated']),
      txHash: blockchainData['txHash'],
      isVerified: true, // Data from blockchain is verified
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'icu_beds': icuBeds,
      'emergency_beds': emergencyBeds,
      'ventilators': ventilators,
      'last_updated': lastUpdated.toIso8601String(),
      'tx_hash': txHash,
      'is_verified': isVerified,
      'additional_capacity': additionalCapacity,
    };
  }

  HospitalCapacityModel copyWith({
    int? icuBeds,
    int? emergencyBeds,
    int? ventilators,
    DateTime? lastUpdated,
    String? txHash,
    bool? isVerified,
    Map<String, dynamic>? additionalCapacity,
  }) {
    return HospitalCapacityModel(
      icuBeds: icuBeds ?? this.icuBeds,
      emergencyBeds: emergencyBeds ?? this.emergencyBeds,
      ventilators: ventilators ?? this.ventilators,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      txHash: txHash ?? this.txHash,
      isVerified: isVerified ?? this.isVerified,
      additionalCapacity: additionalCapacity ?? this.additionalCapacity,
    );
  }

  // Helper methods
  int get totalBeds => icuBeds + emergencyBeds;
  
  bool get hasAvailableCapacity => totalBeds > 0 || ventilators > 0;
  
  String get capacityStatus {
    if (!hasAvailableCapacity) return 'Fără disponibilitate';
    if (totalBeds >= 10) return 'Disponibilitate mare';
    if (totalBeds >= 5) return 'Disponibilitate medie';
    return 'Disponibilitate limitată';
  }

  String get lastUpdatedDisplayText {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);
    
    if (difference.inMinutes < 1) {
      return 'Acum';
    } else if (difference.inHours < 1) {
      return 'Acum ${difference.inMinutes} minute';
    } else if (difference.inDays < 1) {
      return 'Acum ${difference.inHours} ore';
    } else {
      return 'Acum ${difference.inDays} zile';
    }
  }

  bool get isRecentlyUpdated {
    final difference = DateTime.now().difference(lastUpdated);
    return difference.inHours < 6; // Consider recent if updated within 6 hours
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
    if (value is int) {
      // Assume Unix timestamp
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    return DateTime.now();
  }

  @override
  String toString() {
    return 'HospitalCapacityModel(icuBeds: $icuBeds, emergencyBeds: $emergencyBeds, ventilators: $ventilators)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HospitalCapacityModel &&
        other.icuBeds == icuBeds &&
        other.emergencyBeds == emergencyBeds &&
        other.ventilators == ventilators &&
        other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode => Object.hash(icuBeds, emergencyBeds, ventilators, lastUpdated);
}