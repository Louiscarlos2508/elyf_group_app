
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/boutique/application/providers.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/widgets/boutique_header.dart';
import 'package:elyf_groupe_app/core/printing/thermal_printer_service.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:elyf_groupe_app/core/printing/printer_provider.dart';

class PrinterSettingsScreen extends ConsumerStatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  ConsumerState<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends ConsumerState<PrinterSettingsScreen> {
  String _selectedType = 'sunmi'; // sunmi, bluetooth, system
  bool _isLoading = true;
  bool _isTesting = false;
  
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

  Future<void> _attemptAutoReconnect() async {
     final settings = ref.read(boutiqueSettingsServiceProvider);
     if (settings.printerType == 'bluetooth' && settings.printerConnection != null) {
        await _thermalService.connectToAddress(settings.printerConnection!);
     }
     _checkConnection();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    final connected = await _thermalService.isAvailable();
    if (mounted) setState(() => _isConnected = connected);
  }

  Future<void> _loadSettings() async {
    final settingsService = ref.read(boutiqueSettingsServiceProvider);
    setState(() {
      _selectedType = settingsService.printerType;
      _headerController.text = settingsService.receiptHeader;
      _footerController.text = settingsService.receiptFooter;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings(String type) async {
    setState(() => _selectedType = type);
    await ref.read(boutiqueSettingsServiceProvider).setPrinterType(type);
    if (mounted) {
      NotificationService.showSuccess(context, 'Type d\'imprimante mis à jour');
    }
  }

  Future<void> _saveReceiptConfig() async {
    final settings = ref.read(boutiqueSettingsServiceProvider);
    await settings.setReceiptHeader(_headerController.text);
    await settings.setReceiptFooter(_footerController.text);
    if (mounted) {
      NotificationService.showSuccess(context, 'Configuration du reçu enregistrée');
    }
  }

  Future<void> _startScan() async {
    // Permission logic optimized for Android 12+ (API 31+)
    // On newer versions, we don't need location for Bluetooth scanning if we use BLUETOOTH_SCAN
    
    Map<Permission, PermissionStatus> statuses;
    
    if (await Permission.bluetoothScan.isGranted && await Permission.bluetoothConnect.isGranted) {
       // Already granted
       statuses = {};
    } else {
       statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetooth,
        // Location is still needed for some older thermal printers or Android < 12
        Permission.location, 
      ].request();
    }

    final scanDenied = statuses[Permission.bluetoothScan]?.isDenied ?? false;
    final connectDenied = statuses[Permission.bluetoothConnect]?.isDenied ?? false;

    if (scanDenied || connectDenied) {
      if (mounted) {
        NotificationService.showWarning(
          context, 
          'Les permissions Bluetooth sont nécessaires pour trouver des imprimantes.'
        );
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
          // Save connection details
          await ref.read(boutiqueSettingsServiceProvider).setPrinterConnection(device.address);
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
      if (_selectedType == 'sunmi') {
        final sunmi = ref.read(activePrinterProvider);
        await sunmi.initialize();
        await sunmi.printReceipt('TEST D\'IMPRESSION ELYF\n\nImprimante Sunmi OK\n\n\n');
        if (mounted) NotificationService.showSuccess(context, 'Test envoyé au Sunmi');
      } else if (_selectedType == 'bluetooth') {
        if (!_isConnected) {
            if (mounted) NotificationService.showWarning(context, 'Aucune imprimante connectée');
            return;
        }
        await _thermalService.printReceipt('TEST D\'IMPRESSION ELYF\n\nImprimante Bluetooth OK\n\n\n');
        if (mounted) NotificationService.showSuccess(context, 'Test envoyé à l\'imprimante');
      } else {
        if (mounted) NotificationService.showInfo(context, 'Impression test simulée (Système)');
      }
    } catch (e) {
      if (mounted) NotificationService.showError(context, 'Erreur d\'impression: $e');
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
          const BoutiqueHeader(
            title: "IMPRIMANTE",
            subtitle: "Configuration matérielle",
            gradientColors: [Color(0xFF334155), Color(0xFF1E293B)],
            shadowColor: Color(0xFF334155),
            showBackButton: true,
          ),
          SliverFillRemaining(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Sélectionnez le type d'appareil :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  
                  _buildOptionCard(
                    id: 'sunmi',
                    title: 'Terminal Sunmi V2/V3',
                    description: 'Appareil tout-en-un Android avec imprimante intégrée.',
                    icon: Icons.android,
                    color: Colors.orange,
                  ),
                  
                  _buildOptionCard(
                    id: 'bluetooth',
                    title: 'Imprimante Thermique (Bluetooth)',
                    description: 'Imprimante externe connectée via Bluetooth (ESC/POS).',
                    icon: Icons.bluetooth,
                    color: Colors.blue,
                  ),

                  if (_selectedType == 'bluetooth')
                    _buildBluetoothSection(context),
                  
                  _buildOptionCard(
                    id: 'system',
                    title: 'Impression Système',
                    description: 'Utiliser le service d\'print Android standard (PDF).',
                    icon: Icons.print,
                    color: Colors.grey,
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
                      hintText: 'Ex: MA BOUTIQUE ELYF',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _footerController,
                    decoration: const InputDecoration(
                      labelText: 'Pied de page du reçu',
                      hintText: 'Ex: Merci de votre visite !',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saveReceiptConfig,
                    child: const Text('Enregistrer la personnalisation'),
                  ),

                  const SizedBox(height: 32),
                  
                  Center(
                    child: _isTesting 
                      ? const CircularProgressIndicator()
                      : FilledButton.icon(
                          onPressed: _testPrint,
                          icon: const Icon(Icons.print_outlined),
                          label: const Text("Lancer une impression de test"),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                        ),
                  ),
                  const SizedBox(height: 24),
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
                _isConnected ? 'Imprimante Connectée' : 'Aucune connexion',
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
              label: const Text("Scanner les appareils"),
            ),
          if (_isScanning) ...[
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: CircularProgressIndicator()),
            ),
            const SizedBox(height: 8),
            const Text('Recherche en cours...', textAlign: TextAlign.center),
          ],
          if (_devices.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Appareils trouvés :', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            ..._devices.map((d) => ListTile(
                  title: Text(d.device.name ?? "Appareil Inconnu"),
                  subtitle: Text(d.device.address),
                  trailing: const Icon(Icons.chevron_right),
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
      onTap: () => _saveSettings(id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }
}
