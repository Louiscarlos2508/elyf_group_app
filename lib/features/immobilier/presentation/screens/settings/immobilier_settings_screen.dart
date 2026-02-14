
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import 'package:elyf_groupe_app/features/immobilier/presentation/widgets/immobilier_header.dart';
import 'package:elyf_groupe_app/core/printing/thermal_printer_service.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:elyf_groupe_app/core/printing/printer_provider.dart';

class ImmobilierSettingsScreen extends ConsumerStatefulWidget {
  const ImmobilierSettingsScreen({super.key});
 
  @override
  ConsumerState<ImmobilierSettingsScreen> createState() => _ImmobilierSettingsScreenState();
}
 
class _ImmobilierSettingsScreenState extends ConsumerState<ImmobilierSettingsScreen> {
  String _selectedType = 'system'; // sunmi, bluetooth, system
  bool _isLoading = true;
  bool _isTesting = false;
  
  // Automation settings
  bool _autoBillingEnabled = true;
  final _gracePeriodController = TextEditingController();

  // Bluetooth specific
  final _thermalService = ThermalPrinterService();
  List<BluetoothDiscoveryResult> _devices = [];
  bool _isScanning = false;
  bool _isConnected = false;
 
  final _headerController = TextEditingController();
  final _footerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _thermalService.initialize().then((_) {
      _attemptAutoReconnect();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _footerController.dispose();
    _gracePeriodController.dispose();
    super.dispose();
  }

  Future<void> _attemptAutoReconnect() async {
     final settings = ref.read(immobilierSettingsServiceProvider);
     if (settings.printerType == 'bluetooth' && settings.printerAddress != null) {
        await _thermalService.connectToAddress(settings.printerAddress!);
     }
     _checkConnection();
  }

  Future<void> _checkConnection() async {
    final connected = await _thermalService.isAvailable();
    if (mounted) setState(() => _isConnected = connected);
  }

  Future<void> _loadSettings() async {
    final settingsService = ref.read(immobilierSettingsServiceProvider);
    setState(() {
      _selectedType = settingsService.printerType;
      _headerController.text = settingsService.receiptHeader;
      _footerController.text = settingsService.receiptFooter;
      _autoBillingEnabled = settingsService.autoBillingEnabled;
      _gracePeriodController.text = settingsService.overdueGracePeriod.toString();
      _isLoading = false;
    });
  }

  Future<void> _savePrinterType(String type) async {
    setState(() => _selectedType = type);
    await ref.read(immobilierSettingsServiceProvider).setPrinterType(type);
    if (mounted) {
      NotificationService.showSuccess(context, 'Type d\'imprimante mis à jour');
    }
  }

  Future<void> _saveReceiptConfig() async {
    final settings = ref.read(immobilierSettingsServiceProvider);
    await settings.setReceiptHeader(_headerController.text);
    await settings.setReceiptFooter(_footerController.text);
    await settings.setAutoBillingEnabled(_autoBillingEnabled);
    
    final gracePeriod = int.tryParse(_gracePeriodController.text);
    if (gracePeriod != null) {
      await settings.setOverdueGracePeriod(gracePeriod);
    }

    if (mounted) {
      NotificationService.showSuccess(context, 'Paramètres enregistrés');
    }
  }

  Future<void> _startScan() async {
    Map<Permission, PermissionStatus> statuses;
    
    if (await Permission.bluetoothScan.isGranted && await Permission.bluetoothConnect.isGranted) {
       statuses = {};
    } else {
       statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetooth,
        Permission.location, 
      ].request();
    }

    final scanDenied = statuses[Permission.bluetoothScan]?.isDenied ?? false;
    final connectDenied = statuses[Permission.bluetoothConnect]?.isDenied ?? false;

    if (scanDenied || connectDenied) {
      if (mounted) {
        NotificationService.showWarning(context, 'Permissions Bluetooth nécessaires.');
      }
      return;
    }

    setState(() {
      _isScanning = true;
      _devices = [];
    });

    try {
      _thermalService.scanBluetooth().listen((result) {
        if (mounted) {
          setState(() {
            final index = _devices.indexWhere((element) => element.device.address == result.device.address);
            if (index >= 0) {
              _devices[index] = result;
            } else {
              _devices.add(result);
            }
          });
        }
      }).onDone(() {
        if (mounted) setState(() => _isScanning = false);
      });
      
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Erreur de scan: $e');
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() => _isLoading = true);
    try {
      final success = await _thermalService.connectBluetooth(device);
      if (success) {
        if (mounted) {
          NotificationService.showSuccess(context, 'Connecté à ${device.name ?? "Inconnu"}');
          await ref.read(immobilierSettingsServiceProvider).setPrinterAddress(device.address);
          _checkConnection();
        }
      } else {
        if (mounted) NotificationService.showError(context, 'Échec de connexion');
      }
    } catch (e) {
      if (mounted) NotificationService.showError(context, 'Erreur de connexion: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _testPrint() async {
    setState(() => _isTesting = true);
    try {
      final printer = ref.read(activePrinterProvider);
      final success = await printer.printReceipt('TEST D\'IMPRESSION IMMOBILIER\n\nConfiguration OK\n\n\n');
      if (success) {
        if (mounted) NotificationService.showSuccess(context, 'Test envoyé à l\'imprimante');
      } else {
        if (mounted) NotificationService.showError(context, 'L\'imprimante n\'est pas prête');
      }
    } catch (e) {
      if (mounted) NotificationService.showError(context, 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const ImmobilierHeader(
            title: "PARAMÈTRES",
            subtitle: "Configuration globale",
            showBackButton: true,
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Type d'imprimante :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  
                  _buildOptionCard(
                    id: 'sunmi',
                    title: 'Terminal Sunmi V2/V3',
                    description: 'Imprimante intégrée au terminal Android.',
                    icon: Icons.android,
                    color: Colors.orange,
                  ),
                  
                  _buildOptionCard(
                    id: 'bluetooth',
                    title: 'Imprimante Bluetooth',
                    description: 'Imprimante thermique externe ESC/POS.',
                    icon: Icons.bluetooth,
                    color: Colors.blue,
                  ),

                  if (_selectedType == 'bluetooth')
                    _buildBluetoothSection(context),
                  
                  _buildOptionCard(
                    id: 'system',
                    title: 'Impression Système',
                    description: 'Service d\'impression standard (PDF).',
                    icon: Icons.print,
                    color: Colors.grey,
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),
                  const Text("Automatisation :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: const Text('Facturation automatique'),
                    subtitle: const Text('Génère les paiements en attente chaque mois'),
                    value: _autoBillingEnabled,
                    onChanged: (val) => setState(() => _autoBillingEnabled = val),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _gracePeriodController,
                    decoration: const InputDecoration(
                      labelText: 'Délai de grâce supplémentaire (jours)',
                      hintText: 'Ex: 5',
                      border: OutlineInputBorder(),
                      helperText: 'Nombre de jours de tolérance après le jour de paiement prévu dans le contrat',
                    ),
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),
                  const Text("Personnalisation du reçu :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _headerController,
                    decoration: const InputDecoration(
                      labelText: 'En-tête du reçu',
                      hintText: 'Ex: ELYF IMMOBILIER',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _footerController,
                    decoration: const InputDecoration(
                      labelText: 'Pied de page du reçu',
                      hintText: 'Ex: Merci de votre confiance !',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveReceiptConfig,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Enregistrer tous les paramètres'),
                    ),
                  ),

                  const SizedBox(height: 48),
                  Center(
                    child: _isTesting 
                      ? const CircularProgressIndicator()
                      : FilledButton.icon(
                          onPressed: _testPrint,
                          icon: const Icon(Icons.print_outlined),
                          label: const Text("Impression de test"),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                        ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBluetoothSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(_isConnected ? Icons.check_circle : Icons.bluetooth_searching,
                  color: _isConnected ? Colors.green : Colors.blue),
              const SizedBox(width: 8),
              Text(
                _isConnected ? 'Connectée' : 'Déconnectée',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_isConnected)
                TextButton(
                  onPressed: () {
                    _thermalService.disconnect();
                    setState(() => _isConnected = false);
                  },
                  child: const Text('Déconnecter', style: TextStyle(color: Colors.red)),
                )
            ],
          ),
          const Divider(),
          if (!_isScanning && !_isConnected)
            ElevatedButton.icon(
              onPressed: _startScan,
              icon: const Icon(Icons.search),
              label: const Text("Scanner les imprimantes"),
            ),
          if (_isScanning) ...[
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
          if (_devices.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._devices.map((d) => ListTile(
                  title: Text(d.device.name ?? "Inconnu"),
                  subtitle: Text(d.device.address),
                  onTap: () => _connectToDevice(d.device),
                  dense: true,
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String id,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedType == id;
    return GestureDetector(
      onTap: () => _savePrinterType(id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(description, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }
}
