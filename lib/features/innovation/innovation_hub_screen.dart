import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../blockchain/blockchain_service.dart';

class InnovationHubScreen extends StatefulWidget {
  const InnovationHubScreen({super.key});

  @override
  State<InnovationHubScreen> createState() => _InnovationHubScreenState();
}

class _InnovationHubScreenState extends State<InnovationHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 1. AI Farm Assistant State
  final _aiMessages = <Map<String, String>>[
    {
      'sender': 'ai',
      'text': 'Hello Farmer! I am your Smart Agro AI Consultant. Ask me anything about soil nutrients, crop diseases, weather schedules, or crypto grain tokenization.'
    }
  ];
  final _aiInputController = TextEditingController();
  bool _isAiTyping = false;

  // 2. Harvest Tap Mini Game State
  int _harvestScore = 0;
  int _tapLevel = 1;
  double _energy = 100.0;
  Timer? _energyTimer;
  final List<String> _tapQuotes = [
    '+1 Organic Coffee Bean!',
    '+1 Sweet Corn Kernel!',
    '+1 Premium Rice Grain!',
    'Golden Harvest Multiplier!'
  ];
  String _latestHarvest = 'Tap the plant to harvest!';

  // 3. Blockchain Ledger Service
  final _blockchainService = BlockchainLedgerService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Regenerate energy every second
    _energyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _energy < 100.0) {
        setState(() {
          _energy = min(100.0, _energy + 2.0);
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _aiInputController.dispose();
    _energyTimer?.cancel();
    super.dispose();
  }

  // Handle AI Chat Query
  void _sendAiMessage() {
    final text = _aiInputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _aiMessages.add({'sender': 'user', 'text': text});
      _isAiTyping = true;
    });
    _aiInputController.clear();

    // AI Knowledge Engine response logic
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      String reply;
      final lower = text.toLowerCase();

      if (lower.contains('fertilizer') || lower.contains('pupuk') || lower.contains('nutrient')) {
        reply = 'For vegetative growth, prioritize Nitrogen (N). For flowering and grain filling, switch to higher Phosphorus (P) and Potassium (K) with 6.0-6.8 soil pH.';
      } else if (lower.contains('pest') || lower.contains('hama') || lower.contains('disease') || lower.contains('penyakit')) {
        reply = 'Monitor leaf undersides for aphid colonies or fungus blotches. Recommend organic neem oil solution (5ml/L) or Trichoderma bio-fungicide.';
      } else if (lower.contains('token') || lower.contains('blockchain') || lower.contains('crypto') || lower.contains('agro')) {
        reply = 'Smart Agro mints cryptographic SHA-256 blocks for every harvest batch. 1 AGRO token represents fractional forward yield contracts verified on-chain.';
      } else if (lower.contains('weather') || lower.contains('hujan') || lower.contains('cuaca')) {
        reply = 'Optimal planting window: Begin soil tilling 2 weeks prior to rainy season. Ensure adequate drainage ditches to avoid root rot.';
      } else {
        reply = 'Agro Intelligence Note: Your inquiry regarding "$text" has been logged. Recommended practice is maintaining optimal soil humidity (60-70%) and logging batch metrics to the ledger.';
      }

      setState(() {
        _aiMessages.add({'sender': 'ai', 'text': reply});
        _isAiTyping = false;
      });
    });
  }

  // Harvest Tap Game Action
  void _tapHarvest() {
    if (_energy < 5.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Low Energy! Wait for regeneration...'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _energy = max(0.0, _energy - 5.0);
      _harvestScore += _tapLevel;
      if (_harvestScore >= _tapLevel * 20) {
        _tapLevel += 1;
      }
      _latestHarvest = _tapQuotes[Random().nextInt(_tapQuotes.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agro Innovation Hub'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          tabs: const [
            Tab(icon: Icon(Icons.smart_toy_rounded), text: 'AI Advisor'),
            Tab(icon: Icon(Icons.videogame_asset_rounded), text: 'Harvest Tap'),
            Tab(icon: Icon(Icons.security_rounded), text: 'Origin Ledger'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAiAssistantTab(),
          _buildHarvestGameTab(),
          _buildBlockchainLedgerTab(),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: AI Farm Assistant
  // -------------------------------------------------------------
  Widget _buildAiAssistantTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // AI Header Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: isDark ? const Color(0xFF1E2621) : const Color(0xFFE8F5E9),
          child: const Row(
            children: [
              Icon(Icons.bolt_rounded, color: AppTheme.primaryGreen, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Smart Agro AI Agronomist • Offline Knowledge Neural System',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        // Chat Message List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _aiMessages.length,
            itemBuilder: (ctx, index) {
              final msg = _aiMessages[index];
              final isUser = msg['sender'] == 'user';
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppTheme.primaryGreen
                        : (isDark ? const Color(0xFF1E2621) : Colors.white),
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                      bottomLeft: !isUser ? const Radius.circular(0) : const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    msg['text'] ?? '',
                    style: TextStyle(
                      color: isUser ? Colors.white : (isDark ? Colors.white : Colors.black87),
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        if (_isAiTyping)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Agro AI is thinking...',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ),
          ),

        // Chat Input Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _aiInputController,
                    onSubmitted: (_) => _sendAiMessage(),
                    decoration: InputDecoration(
                      hintText: 'Ask about crops, fertilizers, pests...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.send_rounded),
                  onPressed: _sendAiMessage,
                  style: IconButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 2: Harvest Tap Mini Game
  // -------------------------------------------------------------
  Widget _buildHarvestGameTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Score & Level Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E2621), const Color(0xFF1B4D2B)]
                    : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('HARVESTED CROPS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '$_harvestScore',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.primaryGreen),
                    ),
                  ],
                ),
                Container(height: 40, width: 1, color: Colors.grey.withOpacity(0.3)),
                Column(
                  children: [
                    const Text('FARMER LEVEL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      'Lv. $_tapLevel',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.amber.shade800),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Energy Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Stamina / Energy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('${_energy.toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _energy / 100.0,
                  minHeight: 10,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  color: _energy > 20 ? AppTheme.primaryGreen : Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Giant Clickable Plant
          GestureDetector(
            onTap: _tapHarvest,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryGreen.withOpacity(0.15),
                border: Border.all(color: AppTheme.primaryGreen, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.spa_rounded,
                  size: 90,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
          Text(
            _latestHarvest,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap the sacred plant to earn crop points! Energy recovers automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 3: Blockchain Proof of Origin Ledger
  // -------------------------------------------------------------
  Widget _buildBlockchainLedgerTab() {
    final chain = _blockchainService.chain;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          color: isDark ? const Color(0xFF1E2621) : const Color(0xFFE8F5E9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chain Height: ${chain.length} Blocks',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_rounded, size: 14, color: AppTheme.primaryGreen),
                    SizedBox(width: 4),
                    Text(
                      'SHA-256 Verified',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chain.length,
            itemBuilder: (ctx, index) {
              final block = chain[chain.length - 1 - index]; // Newest first
              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'BLOCK #${block.index}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          Text(
                            block.timestamp.split('T').first,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Hash: ${block.hash}',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppTheme.primaryGreen),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Prev Hash: ${block.previousHash}',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.grey),
                      ),
                      const Divider(height: 16),
                      Text(
                        'Payload: ${block.data}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
