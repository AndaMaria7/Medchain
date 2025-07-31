import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'hospital_provider.dart';

class HospitalAdminPage extends StatefulWidget {
  const HospitalAdminPage({Key? key}) : super(key: key);

  @override
  State<HospitalAdminPage> createState() => _HospitalAdminPageState();
}

class _HospitalAdminPageState extends State<HospitalAdminPage> {
  final _icuController = TextEditingController();
  final _emergencyController = TextEditingController();
  final _ventilatorController = TextEditingController();

  @override
  void dispose() {
    _icuController.dispose();
    _emergencyController.dispose();
    _ventilatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Admin'),
      ),
      body: Consumer<HospitalProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!provider.isConnected) ...[
                  Center(
                    child: ElevatedButton(
                      onPressed: provider.connectWallet,
                      child: const Text('Connect Wallet'),
                    ),
                  ),
                ] else ...[
                  Text(
                    'Wallet: ${provider.hospitalAddress}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _icuController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ICU Beds',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emergencyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Emergency Beds',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ventilatorController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Ventilators',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final icu = int.tryParse(_icuController.text) ?? 0;
                        final emergency = int.tryParse(_emergencyController.text) ?? 0;
                        final vent = int.tryParse(_ventilatorController.text) ?? 0;
                        await provider.updateCapacity(
                          icuBeds: icu,
                          emergencyBeds: emergency,
                          ventilators: vent,
                        );
                        if (provider.error == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Capacity updated')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(provider.error!)),
                          );
                        }
                      },
                      child: const Text('Submit'),
                    ),
                  ),
                  if (provider.currentCapacity != null) ...[
                    const SizedBox(height: 24),
                    Text('Current Capacity:', style: Theme.of(context).textTheme.bodyLarge),
                    Text('ICU Beds: ${provider.currentCapacity!.icuBeds}'),
                    Text('Emergency Beds: ${provider.currentCapacity!.emergencyBeds}'),
                    Text('Ventilators: ${provider.currentCapacity!.ventilators}'),
                    Text('Last Updated: ${provider.currentCapacity!.lastUpdated}'),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
