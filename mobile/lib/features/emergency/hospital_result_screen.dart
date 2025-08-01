import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:medchain_emergency/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class HospitalResultScreen extends StatefulWidget {
  final Map<String, dynamic>? matchedHospital;
  final double? matchScore;
  final String? emergencyId;
  final String? jobId;

  const HospitalResultScreen({
    Key? key,
    required this.matchedHospital,
    this.matchScore,
    this.emergencyId,
    this.jobId,
  }) : super(key: key);

  @override
  State<HospitalResultScreen> createState() => _HospitalResultScreenState();
}

class _HospitalResultScreenState extends State<HospitalResultScreen> {

  
  @override
  void initState() {
    super.initState();
  }

// Helper methods with proper null safety
String _getHospitalName() {
  final hospital = widget.matchedHospital;
  if (hospital == null) return 'Hospital';
  
  return hospital['name'] as String? ?? 
         hospital['hospitalName'] as String? ?? 
         'Hospital';
}

String _getHospitalPhone() {
  final hospital = widget.matchedHospital;
  if (hospital == null) return '';
  
  return hospital['phone'] as String? ?? 
         hospital['phoneNumber'] as String? ?? 
         hospital['contact']?['phone'] as String? ?? 
         '';
}

String _getHospitalAddress() {
  final hospital = widget.matchedHospital;
  if (hospital == null) return 'Address not available';
  
  return hospital['address'] as String? ?? 
         hospital['location']?.toString() ?? 
         'Address not available';
}
  
  // Helper methods to safely extract hospital data
  double _getHospitalLatitude() {
    final hospital = widget.matchedHospital;
    if (hospital == null) return 0.0;
    
    // Try to parse latitude from various possible fields
    final lat = hospital['latitude'] ?? hospital['lat'] ?? 
               hospital['location']?['latitude'] ?? hospital['location']?['lat'];
    
    // Handle different data types (double, int, string)
    if (lat is double) return lat;
    if (lat is int) return lat.toDouble();
    if (lat is String) return double.tryParse(lat) ?? 0.0;
    
    return 0.0;
  }

  double _getHospitalLongitude() {
    final hospital = widget.matchedHospital;
    if (hospital == null) return 0.0;
    
    // Try to parse longitude from various possible fields
    final lng = hospital['longitude'] ?? hospital['lng'] ?? 
               hospital['location']?['longitude'] ?? hospital['location']?['lng'];
    
    // Handle different data types (double, int, string)
    if (lng is double) return lng;
    if (lng is int) return lng.toDouble();
    if (lng is String) return double.tryParse(lng) ?? 0.0;
    
    return 0.0;
    return 26.1025; // Default to Bucharest
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A2151), Color(0xFF0D1128)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Recommended Hospital',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 40), 
                  ],
                ),
              ),
              
              // Map Preview
              _buildMapPreview(),
              const SizedBox(height: 20),
              
              // Hospital Details
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Match Score Card
                      _buildMatchScoreCard(),
                      const SizedBox(height: 20),
                      
                      // Hospital Details
                      _buildHospitalDetails(),
                      
                      // Action Buttons
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.navigation_outlined,
                              label: 'Navigate',
                              onPressed: _navigateToHospital,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade700,
                                  Colors.blue.shade500,
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.phone_outlined,
                              label: 'Call',
                              onPressed: _callHospital,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade700,
                                  Colors.green.shade500,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

  }

  Widget _buildMapPreview() {
    final lat = _getHospitalLatitude();
    final lng = _getHospitalLongitude();
    
    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withOpacity(0.8),
            Colors.purple.withOpacity(0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Use a solid color background instead of network image
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                // Pattern with icons instead of network image
                color: Colors.blue.shade900.withOpacity(0.3),
              ),
              // child: const Center(
              //   child: Icon(
              //     Icons.map,
              //     size: 80,
              //     color: Colors.white10,
              //   ),
              // ),
            ),
          ),
          
          // Content layout with car on right and rest centered
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Car indicator in right corner
                if (widget.matchedHospital?['distance'] != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_car,
                            color: Colors.blue[800],
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.matchedHospital?['distance']?.toStringAsFixed(1) ?? '0.0'} km',
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _getHospitalName(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
              
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _navigateToHospital,
                  icon: const Icon(Icons.directions, size: 16),
                  label: const Text('Open in Maps', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue[800],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: const Size(120, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
                ],
              ),
            ),
        ]
        
      ),
    );
  }

Widget _buildHospitalDetails() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Section header with icon
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.local_hospital,
              color: Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Hospital Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      
      // Hospital basic info
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Centered hospital name with larger font
            Text(
              _getHospitalName(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Details aligned left
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem(
                  icon: Icons.location_on,
                  title: 'Address',
                  value: _getHospitalAddress(),
                ),
                _buildDetailItem(
                  icon: Icons.phone,
                  title: 'Emergency Phone',
                  value: _getHospitalPhone(),
                ),
                if (widget.matchedHospital?['distance'] != null)
                  _buildDetailItem(
                    icon: Icons.directions_car,
                    title: 'Distance',
                    value: '${widget.matchedHospital?['distance']} km',
                  ),
                if (widget.matchedHospital?['availableBeds'] != null)
                  _buildDetailItem(
                    icon: Icons.bed,
                    title: 'Available Beds',
                    value: '${widget.matchedHospital?['availableBeds']} beds',
                  ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      
      // Hospital capabilities
      if (_hasCapabilityData())
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Hospital Capabilities',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: _buildCapabilityBadges(),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

Widget _buildDetailItem({
  required IconData icon,
  required String title,
  required String value,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

bool _hasCapabilityData() {
  final hospital = widget.matchedHospital;
  return hospital?['has_cardiac_surgery'] != null ||
         hospital?['has_trauma_center'] != null ||
         hospital?['specialization'] != null;
}

List<Widget> _buildCapabilityBadges() {
  final hospital = widget.matchedHospital;
  List<Widget> badges = [];
  
  // Add specialization badge
  if (hospital?['specialization'] != null) {
    badges.add(_buildCapabilityBadge(
      Icons.medical_services,
      hospital!['specialization'].toString(),
      Colors.blue,
    ));
  }
  
  // Add cardiac surgery badge
  if (hospital!['has_cardiac_surgery'] == true) {
    badges.add(_buildCapabilityBadge(
      Icons.favorite,
      'Cardiac Surgery',
      Colors.red,
    ));
  }
  
  // Add trauma center badge
  if (hospital['has_trauma_center'] == true) {
    badges.add(_buildCapabilityBadge(
      Icons.local_hospital,
      'Trauma Center',
      Colors.orange,
    ));
  }
  
  // Add emergency badge (always present)
  badges.add(_buildCapabilityBadge(
    Icons.emergency,
    '24/7 Emergency',
    Colors.green,
  ));
  
  return badges;
}

Widget _buildCapabilityBadge(IconData icon, String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: color.withOpacity(0.3),
        width: 1,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
  
  Widget _buildMatchScoreCard() {
    // Ensure score is displayed correctly (not as 9250%)
    final rawScore = widget.matchScore ?? 0.0;
    final score = rawScore > 1.0 ? rawScore : rawScore * 100;
    final scoreText = score.toStringAsFixed(0);
    
    // Determine color based on score
    Color primaryColor;
    if (score >= 80) {
      primaryColor = Colors.green.shade600;
    } else if (score >= 60) {
      primaryColor = Colors.blue.shade600;
    } else if (score >= 40) {
      primaryColor = Colors.orange.shade600;
    } else {
      primaryColor = Colors.red.shade600;
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.9),
            primaryColor,
            primaryColor.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_outlined,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'Match Analysis',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular progress indicator
              SizedBox(
                width: 70,
                height: 70,
                child: Stack(
                  children: [
                    // Background circle
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    // Progress circle
                    Center(
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          value: score / 100,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 6,
                        ),
                      ),
                    ),
                    // Score text
                    Center(
                      child: Text(
                        '$scoreText%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getMatchQualityText(score),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Based on your emergency needs and hospital capabilities',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Match factors
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildMatchFactors(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2);
  }
  
List<Widget> _buildMatchFactors() {
  final hospital = widget.matchedHospital;
  
  return [
    if (hospital?['has_trauma_center'] == true)
      _buildMatchFactor(Icons.local_hospital, 'Trauma Center'),
    if (hospital?['has_cardiac_surgery'] == true)
      _buildMatchFactor(Icons.favorite, 'Cardiac Surgery'),
    if (hospital?['availableBeds'] != null && hospital?['availableBeds'] > 5)
      _buildMatchFactor(Icons.bed, '${hospital?['availableBeds']} Beds'),
    if (hospital?['average_wait_time_minutes'] != null && hospital?['average_wait_time_minutes'] < 30)
      _buildMatchFactor(Icons.timer, 'Short Wait'),
    _buildMatchFactor(Icons.location_on, 'Optimal Location'),
  ];
}
  
  Widget _buildMatchFactor(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getMatchQualityText(double score) {
    if (score >= 80) {
      return 'Excellent Match';
    } else if (score >= 60) {
      return 'Good Match';
    } else if (score >= 40) {
      return 'Fair Match';
    } else {
      return 'Poor Match';
    }
  }
  
  Widget _buildSpecialtyBadge({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCapacityIndicator({required String label, required int value, required int total, required Color color}) {
    final percentage = (value / total).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            Text(
              '$value/$total',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            // Background
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Progress
            Container(
              height: 8,
              width: double.infinity * percentage,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required LinearGradient gradient,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _navigateToHospital() async {
    
    // Get hospital coordinates
    final lat = _getHospitalLatitude();
    final lng = _getHospitalLongitude();
    final name = Uri.encodeComponent(_getHospitalName());
    
    // Create Google Maps URL
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$name');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        _showErrorDialog('Could not open maps application');
      }
    }
  }
  
  Future<void> _callHospital() async {
    final phone = widget.matchedHospital?['phoneNumber'] as String? ?? '';
    if (phone.isEmpty) {
      _showErrorDialog('No phone number available');
      return;
    }
    
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        _showErrorDialog('Could not make phone call');
      }
    }
  }
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
