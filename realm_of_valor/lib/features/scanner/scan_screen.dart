import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import '../../../data/models/card_model.dart';
import '../../../data/models/inventory_model.dart';
import '../../../services/event_bus.dart';
import '../../../core/di.dart';
import '../inventory/providers.dart';
import '../character/providers.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isScanning = false;
  bool _hasPermission = false;
  final List<String> _scanLog = [];

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasPermission = status.isGranted;
    });
    
    if (_hasPermission) {
      _startScanning();
    } else {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'The QR scanner needs camera permission to scan cards and add them to your inventory.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _requestCameraPermission();
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
    });
  }

  void _stopScanning() {
    setState(() {
      _isScanning = false;
    });
  }

  void _addToLog(String message) {
    setState(() {
      _scanLog.add('${DateTime.now().toString().substring(11, 19)}: $message');
      if (_scanLog.length > 10) {
        _scanLog.removeAt(0);
      }
    });
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null && _isScanning) {
        _processScannedCode(scanData.code!);
      }
    });
  }

  void _processScannedCode(String code) {
    _addToLog('Scanned: $code');
    _stopScanning();

    try {
      // Parse the QR code data
      final cardData = _parseCardData(code);
      if (cardData != null) {
        _showCardFoundDialog(cardData);
      } else {
        _showInvalidCodeDialog();
      }
    } catch (e) {
      _addToLog('Error processing code: $e');
      _showInvalidCodeDialog();
    }
  }

  Map<String, dynamic>? _parseCardData(String code) {
    try {
      // QR code format: "ROV_CARD:{cardId}:{cardType}:{rarity}:{stats}"
      if (code.startsWith('ROV_CARD:')) {
        final parts = code.split(':');
        if (parts.length >= 4) {
          return {
            'cardId': parts[1],
            'cardType': parts[2],
            'rarity': parts[3],
            'stats': parts.length > 4 ? parts[4] : null,
          };
        }
      }
      
      // Skill unlock format: "ROV_SKILL:{skillId}:{skillName}"
      if (code.startsWith('ROV_SKILL:')) {
        final parts = code.split(':');
        if (parts.length >= 3) {
          return {
            'type': 'skill',
            'skillId': parts[1],
            'skillName': parts[2],
          };
        }
      }
      
      // Quest unlock format: "ROV_QUEST:{questId}:{questName}"
      if (code.startsWith('ROV_QUEST:')) {
        final parts = code.split(':');
        if (parts.length >= 3) {
          return {
            'type': 'quest',
            'questId': parts[1],
            'questName': parts[2],
          };
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  void _showCardFoundDialog(Map<String, dynamic> cardData) {
    if (cardData['type'] == 'skill') {
      _showSkillUnlockDialog(cardData);
    } else if (cardData['type'] == 'quest') {
      _showQuestUnlockDialog(cardData);
    } else {
      _showCardAddDialog(cardData);
    }
  }

  void _showCardAddDialog(Map<String, dynamic> cardData) {
    final cardName = _getCardName(cardData['cardId']);
    final cardType = cardData['cardType'];
    final rarity = cardData['rarity'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Card Found!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: $cardName'),
            Text('Type: $cardType'),
            Text('Rarity: $rarity'),
            const SizedBox(height: 16),
            const Text('Add this card to your inventory?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startScanning();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addCardToInventory(cardData);
            },
            child: const Text('Add to Inventory'),
          ),
        ],
      ),
    );
  }

  void _showSkillUnlockDialog(Map<String, dynamic> skillData) {
    final skillName = skillData['skillName'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skill Unlocked!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.psychology, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            Text('You have unlocked: $skillName'),
            const SizedBox(height: 8),
            const Text('This skill is now available in your skill tree!'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _unlockSkill(skillData);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showQuestUnlockDialog(Map<String, dynamic> questData) {
    final questName = questData['questName'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quest Discovered!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            Text('New Quest: $questName'),
            const SizedBox(height: 8),
            const Text('This quest is now available in your quest log!'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _unlockQuest(questData);
            },
            child: const Text('Accept Quest'),
          ),
        ],
      ),
    );
  }

  void _showInvalidCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invalid QR Code'),
        content: const Text(
          'This QR code is not recognized as a valid Realm of Valor card or item.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startScanning();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  String _getCardName(String cardId) {
    // Map card IDs to readable names
    final cardNames = {
      'basic_sword': 'Basic Sword',
      'health_potion': 'Health Potion',
      'fireball': 'Fireball',
      'leather_armor': 'Leather Armor',
      'iron_helmet': 'Iron Helmet',
      'magic_ring': 'Magic Ring',
      'lightning_bolt': 'Lightning Bolt',
      'healing_spell': 'Healing Spell',
      'steel_sword': 'Steel Sword',
      'dragon_scale': 'Dragon Scale',
    };
    
    return cardNames[cardId] ?? cardId;
  }

  void _addCardToInventory(Map<String, dynamic> cardData) {
    final eventBus = ref.read(eventBusProvider);
    
    // Create a new card instance
    final cardInstance = CardInstance(
      instanceId: 'scanned_${DateTime.now().millisecondsSinceEpoch}',
      cardId: cardData['cardId'],
      durability: 100,
      upgrades: null,
      flags: null,
    );
    
    // Publish event to add card to inventory
    eventBus.publish(Event(
      type: 'card.scanned',
      data: {
        'cardInstance': cardInstance.toJson(),
        'cardData': cardData,
      },
    ));
    
    _addToLog('Added ${_getCardName(cardData['cardId'])} to inventory');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${_getCardName(cardData['cardId'])} to inventory!'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'View Inventory',
          onPressed: () {
            Navigator.of(context).pushNamed('/inventory');
          },
        ),
      ),
    );
    
    _startScanning();
  }

  void _unlockSkill(Map<String, dynamic> skillData) {
    final eventBus = ref.read(eventBusProvider);
    
    eventBus.publish(Event(
      type: 'skill.unlocked',
      data: {
        'skillId': skillData['skillId'],
        'skillName': skillData['skillName'],
      },
    ));
    
    _addToLog('Unlocked skill: ${skillData['skillName']}');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Skill unlocked: ${skillData['skillName']}!'),
        backgroundColor: Colors.blue,
        action: SnackBarAction(
          label: 'View Character',
          onPressed: () {
            Navigator.of(context).pushNamed('/character');
          },
        ),
      ),
    );
    
    _startScanning();
  }

  void _unlockQuest(Map<String, dynamic> questData) {
    final eventBus = ref.read(eventBusProvider);
    
    eventBus.publish(Event(
      type: 'quest.unlocked',
      data: {
        'questId': questData['questId'],
        'questName': questData['questName'],
      },
    ));
    
    _addToLog('Unlocked quest: ${questData['questName']}');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quest unlocked: ${questData['questName']}!'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'View Quests',
          onPressed: () {
            Navigator.of(context).pushNamed('/quests');
          },
        ),
      ),
    );
    
    _startScanning();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner'),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.stop : Icons.play_arrow),
            onPressed: _isScanning ? _stopScanning : _startScanning,
          ),
        ],
      ),
      body: Column(
        children: [
          // Scanner View
          Expanded(
            flex: 3,
            child: _hasPermission
                ? QRView(
                    key: qrKey,
                    onQRViewCreated: _onQRViewCreated,
                    overlay: QrScannerOverlayShape(
                      borderColor: Colors.blue,
                      borderRadius: 10,
                      borderLength: 30,
                      borderWidth: 10,
                      cutOutSize: 250,
                    ),
                  )
                : Container(
                    color: Colors.black,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 64, color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Camera permission required',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Grant camera permission to scan QR codes',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          
          // Controls and Info
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status: ${_isScanning ? 'Scanning' : 'Stopped'}',
                      style: TextStyle(
                        color: _isScanning ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!_hasPermission)
                      ElevatedButton(
                        onPressed: _requestCameraPermission,
                        child: const Text('Grant Permission'),
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Instructions
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'How to use:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text('• Point camera at a Realm of Valor QR code'),
                        const Text('• Cards will be added to your inventory'),
                        const Text('• Skills will be unlocked in your skill tree'),
                        const Text('• Quests will be added to your quest log'),
                        const SizedBox(height: 8),
                        const Text(
                          'Supported formats:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Text('• ROV_CARD:cardId:type:rarity:stats'),
                        const Text('• ROV_SKILL:skillId:skillName'),
                        const Text('• ROV_QUEST:questId:questName'),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Scan Log
                if (_scanLog.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Scan Log',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _scanLog.clear();
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 100,
                            child: ListView.builder(
                              itemCount: _scanLog.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    _scanLog[index],
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

