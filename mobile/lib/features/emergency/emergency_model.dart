enum EmergencyType {
  general,
  cardiac,
  trauma,
  respiratory,
  neurological,
  pediatric,
  obstetric,
}

enum EmergencyStatus {
  created,
  searching,
  matched,
  dispatched,
  arrived,
  resolved,
  cancelled,
}

enum EmergencySeverity {
  low(1, 'Scăzută'),
  medium(5, 'Medie'),
  high(7, 'Mare'),
  critical(9, 'Critică'),
  extreme(10, 'Extremă');

  const EmergencySeverity(this.value, this.displayName);
  final int value;
  final String displayName;
}

class EmergencyModel {
  final String id;
  final double latitude;
  final double longitude;
  final String? address;
  final EmergencyType type;
  final EmergencySeverity severity;
  final EmergencyStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? matchedHospitalId;
  final double? matchScore;
  final String? notes;
  final String? reporterAddress; // Blockchain address
  final String? transactionHash;
  final Map<String, dynamic>? additionalData;

  const EmergencyModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.type,
    required this.severity,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.matchedHospitalId,
    this.matchScore,
    this.notes,
    this.reporterAddress,
    this.transactionHash,
    this.additionalData,
  });

  factory EmergencyModel.fromJson(Map<String, dynamic> json) {
    return EmergencyModel(
      id: json['emergencyId'] ?? json['id'] ?? '',
      latitude: _parseDouble(json['location']?['lat'] ?? json['latitude'] ?? 0.0),
      longitude: _parseDouble(json['location']?['lng'] ?? json['longitude'] ?? 0.0),
      address: json['address'] ?? json['location_address'],
      type: _parseEmergencyType(json['type']),
      severity: _parseEmergencySeverity(json['severity']),
      status: _parseEmergencyStatus(json['status']),
      createdAt: _parseDateTime(json['timestamp'] ?? json['createdAt'] ?? json['created_at']),
      updatedAt: json['updatedAt'] != null ? _parseDateTime(json['updatedAt']) : null,
      matchedHospitalId: json['matchedHospitalId'] ?? json['matched_hospital_id'],
      matchScore: json['matchScore'] != null ? _parseDouble(json['matchScore']) : null,
      notes: json['notes'],
      reporterAddress: json['reporterAddress'] ?? json['reporter_address'],
      transactionHash: json['transactionHash'] ?? json['transaction_hash'],
      additionalData: json['additionalData'] ?? json['additional_data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emergencyId': id,
      'location': {
        'lat': latitude,
        'lng': longitude,
      },
      'address': address,
      'type': type.name,
      'severity': severity.value,
      'status': status.name,
      'timestamp': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'matchedHospitalId': matchedHospitalId,
      'matchScore': matchScore,
      'notes': notes,
      'reporterAddress': reporterAddress,
      'transactionHash': transactionHash,
      'additionalData': additionalData,
    };
  }

  EmergencyModel copyWith({
    String? id,
    double? latitude,
    double? longitude,
    String? address,
    EmergencyType? type,
    EmergencySeverity? severity,
    EmergencyStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? matchedHospitalId,
    double? matchScore,
    String? notes,
    String? reporterAddress,
    String? transactionHash,
    Map<String, dynamic>? additionalData,
  }) {
    return EmergencyModel(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      matchedHospitalId: matchedHospitalId ?? this.matchedHospitalId,
      matchScore: matchScore ?? this.matchScore,
      notes: notes ?? this.notes,
      reporterAddress: reporterAddress ?? this.reporterAddress,
      transactionHash: transactionHash ?? this.transactionHash,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  // Helper methods
  String get typeDisplayName {
    switch (type) {
      case EmergencyType.general:
        return 'General';
      case EmergencyType.cardiac:
        return 'Cardiac';
      case EmergencyType.trauma:
        return 'Traumă';
      case EmergencyType.respiratory:
        return 'Respirator';
      case EmergencyType.neurological:
        return 'Neurologic';
      case EmergencyType.pediatric:
        return 'Pediatric';
      case EmergencyType.obstetric:
        return 'Obstetric';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case EmergencyStatus.created:
        return 'Creată';
      case EmergencyStatus.searching:
        return 'Se caută spital';
      case EmergencyStatus.matched:
        return 'Spital găsit';
      case EmergencyStatus.dispatched:
        return 'Ambulanța trimisă';
      case EmergencyStatus.arrived:
        return 'Ajuns la spital';
      case EmergencyStatus.resolved:
        return 'Rezolvată';
      case EmergencyStatus.cancelled:
        return 'Anulată';
    }
  }

  bool get isActive => status != EmergencyStatus.resolved && status != EmergencyStatus.cancelled;
  
  bool get isMatched => matchedHospitalId != null;

  Duration get duration => DateTime.now().difference(createdAt);

  String get durationDisplayText {
    final duration = this.duration;
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
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

  static EmergencyType _parseEmergencyType(dynamic value) {
    if (value is String) {
      for (final type in EmergencyType.values) {
        if (type.name == value.toLowerCase()) {
          return type;
        }
      }
    }
    return EmergencyType.general;
  }

  static EmergencySeverity _parseEmergencySeverity(dynamic value) {
    int severityValue = 5; // Default medium
    
    if (value is int) {
      severityValue = value;
    } else if (value is String) {
      severityValue = int.tryParse(value) ?? 5;
    }

    if (severityValue <= 2) return EmergencySeverity.low;
    if (severityValue <= 6) return EmergencySeverity.medium;
    if (severityValue <= 8) return EmergencySeverity.high;
    if (severityValue <= 9) return EmergencySeverity.critical;
    return EmergencySeverity.extreme;
  }

  static EmergencyStatus _parseEmergencyStatus(dynamic value) {
    if (value is String) {
      for (final status in EmergencyStatus.values) {
        if (status.name == value.toLowerCase()) {
          return status;
        }
      }
    }
    return EmergencyStatus.created;
  }

  @override
  String toString() {
    return 'EmergencyModel(id: $id, type: $type, severity: $severity, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmergencyModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}