import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/wallet_service.dart';

class HospitalAdminScreen extends StatefulWidget {
  const HospitalAdminScreen({Key? key}) : super(key: key);

  @override
  _HospitalAdminScreenState createState() => _HospitalAdminScreenState();
}

class _HospitalAdminScreenState extends State<HospitalAdminScreen> {
  // Form controllers
  final TextEditingController _icuBedsController = TextEditingController();
  final TextEditingController _emergencyBedsController = TextEditingController();
  final TextEditingController _ventilatorsController = TextEditingController();
  
  // Medical personnel controllers
  final TextEditingController _cardiologistsController = TextEditingController();
  final TextEditingController _surgeonsController = TextEditingController();
  final TextEditingController _pediatriciansController = TextEditingController();
  final TextEditingController _neurologistsController = TextEditingController();
  final TextEditingController _emergencyDoctorsController = TextEditingController();
  
  bool _isLoading = false;
  String _statusMessage = '';
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _initializeWallet();
  }

  Future<void> _initializeWallet() async {
    final walletService = Provider.of<WalletService>(context, listen: false);
    await walletService.initialize();
  }

  @override
  void dispose() {
    _icuBedsController.dispose();
    _emergencyBedsController.dispose();
    _ventilatorsController.dispose();
    _cardiologistsController.dispose();
    _surgeonsController.dispose();
    _pediatriciansController.dispose();
    _neurologistsController.dispose();
    _emergencyDoctorsController.dispose();
    super.dispose();
  }

  Future<void> _connectWallet() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Connecting wallet...';
    });

    final walletService = Provider.of<WalletService>(context, listen: false);
    final result = await walletService.connectWallet();

    setState(() {
      _isLoading = false;
      if (result) {
        _statusMessage = 'Wallet connected successfully!';
        _isSuccess = true;
      } else {
        _statusMessage = 'Failed to connect wallet';
        _isSuccess = false;
      }
    });
  }

  Future<void> _updateCapacity() async {
    if (!_validateCapacityInputs()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Updating hospital capacity...';
    });

    final walletService = Provider.of<WalletService>(context, listen: false);
    
    final result = await walletService.updateCapacity(
      int.parse(_icuBedsController.text),
      int.parse(_emergencyBedsController.text),
      int.parse(_ventilatorsController.text),
    );

    setState(() {
      _isLoading = false;
      if (result['success']) {
        _statusMessage = 'Capacity updated successfully!';
        _isSuccess = true;
      } else {
        _statusMessage = 'Failed to update capacity: ${result['error']}';
        _isSuccess = false;
      }
    });
  }

  Future<void> _updateMedicalPersonnel() async {
    if (!_validatePersonnelInputs()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Updating medical personnel...';
    });

    final walletService = Provider.of<WalletService>(context, listen: false);
    
    final personnelCounts = {
      'cardiologist': int.parse(_cardiologistsController.text),
      'surgeon': int.parse(_surgeonsController.text),
      'pediatrician': int.parse(_pediatriciansController.text),
      'neurologist': int.parse(_neurologistsController.text),
      'emergency': int.parse(_emergencyDoctorsController.text),
    };

    final result = await walletService.updateMedicalPersonnel(personnelCounts);

    setState(() {
      _isLoading = false;
      if (result['success']) {
        _statusMessage = 'Medical personnel updated successfully!';
        _isSuccess = true;
      } else {
        _statusMessage = 'Failed to update medical personnel: ${result['error']}';
        _isSuccess = false;
      }
    });
  }

  bool _validateCapacityInputs() {
    if (_icuBedsController.text.isEmpty ||
        _emergencyBedsController.text.isEmpty ||
        _ventilatorsController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Please fill in all capacity fields';
        _isSuccess = false;
      });
      return false;
    }
    return true;
  }

  bool _validatePersonnelInputs() {
    if (_cardiologistsController.text.isEmpty ||
        _surgeonsController.text.isEmpty ||
        _pediatriciansController.text.isEmpty ||
        _neurologistsController.text.isEmpty ||
        _emergencyDoctorsController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Please fill in all medical personnel fields';
        _isSuccess = false;
      });
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final walletService = Provider.of<WalletService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Admin Dashboard'),
        actions: [
          if (walletService.isConnected)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  'Connected: ${walletService.walletAddress?.substring(0, 6)}...${walletService.walletAddress?.substring(walletService.walletAddress!.length - 4)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!walletService.isConnected)
              ElevatedButton(
                onPressed: _isLoading ? null : _connectWallet,
                child: const Text('Connect Hospital Wallet'),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Hospital Resource Management',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Capacity Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Update Hospital Capacity',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _icuBedsController,
                            decoration: const InputDecoration(
                              labelText: 'ICU Beds Available',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emergencyBedsController,
                            decoration: const InputDecoration(
                              labelText: 'Emergency Beds Available',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _ventilatorsController,
                            decoration: const InputDecoration(
                              labelText: 'Ventilators Available',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _updateCapacity,
                            child: const Text('Update Capacity'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Medical Personnel Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Update Medical Personnel',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _cardiologistsController,
                            decoration: const InputDecoration(
                              labelText: 'Cardiologists Available Today',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _surgeonsController,
                            decoration: const InputDecoration(
                              labelText: 'Surgeons Available Today',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _pediatriciansController,
                            decoration: const InputDecoration(
                              labelText: 'Pediatricians Available Today',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _neurologistsController,
                            decoration: const InputDecoration(
                              labelText: 'Neurologists Available Today',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emergencyDoctorsController,
                            decoration: const InputDecoration(
                              labelText: 'Emergency Doctors Available Today',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _updateMedicalPersonnel,
                            child: const Text('Update Medical Personnel'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 16),
            
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isSuccess ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _isSuccess ? Colors.green.shade900 : Colors.red.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
