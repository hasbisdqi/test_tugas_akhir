import 'dart:math';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? suggestedActions;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.suggestedActions,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AiAssistantService {
  static final AiAssistantService _instance = AiAssistantService._internal();
  factory AiAssistantService() => _instance;
  AiAssistantService._internal();

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get history => List.unmodifiable(_messages);

  static const List<String> quickPromptSuggestions = [
    'How to optimize rice irrigation in dry season?',
    'What causes yellow leaf curl on chili peppers?',
    'Explain how Solana blockchain secures crop traceability',
    'Best organic fertilizer composition for hydroponics',
    'Current market demand trends for robusta coffee',
  ];

  void addMessage(ChatMessage msg) {
    _messages.add(msg);
  }

  void clearHistory() {
    _messages.clear();
  }

  /// AI Knowledge Engine with contextual rules, diagnostics, and domain wisdom
  Future<ChatMessage> respondToPrompt(String prompt) async {
    final query = prompt.toLowerCase();
    await Future.delayed(const Duration(milliseconds: 600)); // Simulating natural inference latency

    String responseText = '';
    List<String> nextSuggestions = [];

    if (query.contains('irrigation') || query.contains('water') || query.contains('dry season') || query.contains('padi')) {
      responseText =
          "🌾 **Smart Irrigation Advisory**:\n"
          "1. Implement **AWD (Alternate Wetting and Drying)**: Allow the field to dry out naturally for 2-5 days after disappearance of water pond before re-irrigating to 5cm depth. This saves up to 30% water.\n"
          "2. Soil moisture sensor calibration: Maintain soil water potential above -20 kPa during vegetative stages.\n"
          "3. Critical stage: Keep flooded during flowering/panicle initiation to prevent spikelet sterility.";
      nextSuggestions = ['Calculate AWD water savings', 'View sensor thresholds', 'Set irrigation reminder'];
    } else if (query.contains('chili') || query.contains('cabai') || query.contains('leaf curl') || query.contains('yellow')) {
      responseText =
          "🌶️ **Crop Diagnostic: Pepper Yellow Leaf Curl Virus (PepYLCV)**:\n"
          "• **Vector**: Transmitted primarily by Whiteflies (*Bemisia tabaci*).\n"
          "• **Immediate Action**: Install yellow sticky traps (15-20 traps/ha) and introduce neem oil spray (5ml/L) or entomopathogenic fungi (*Beauveria bassiana*).\n"
          "• **Sanitation**: Rogue and destroy severely infected plants to prevent viral spread.";
      nextSuggestions = ['Organic pesticide recipe', 'Whitefly lifecycle guide', 'Trace seed batch'];
    } else if (query.contains('blockchain') || query.contains('solana') || query.contains('traceability') || query.contains('crypto')) {
      responseText =
          "⛓️ **Agro-Traceability on Solana / SHA-256 Ledger**:\n"
          "• Every harvest batch is minted with an immutable cryptographic hash (SHA-256 block).\n"
          "• Sensor metadata (humidity, GPS origin, pesticide test) is hashed into the block state.\n"
          "• Any downstream tampering of batch weights or chemical grades immediately invalidates the cryptographic proof chain!";
      nextSuggestions = ['Inspect genesis block', 'Run tamper test', 'Simulate block mining'];
    } else if (query.contains('fertilizer') || query.contains('pupuk') || query.contains('hydroponic') || query.contains('organic')) {
      responseText =
          "🌱 **Organic Fertilizer & Nutrient Formula**:\n"
          "• **Liquid Organic Fertilizer (POC)**: Ferment banana peels (potassium), eggshells (calcium), and fermented goat manure extract (nitrogen).\n"
          "• **Target EC/TDS**: Keep vegetative leafy greens at EC 1.4 - 1.8 mS/cm, pH 5.8 - 6.5.\n"
          "• **Tip**: Aerate nutrient tanks continuously with an air stone to prevent Pythium root rot.";
      nextSuggestions = ['Check sensor pH levels', 'Set nutrient cycle alert'];
    } else if (query.contains('coffee') || query.contains('kopi') || query.contains('market') || query.contains('price') || query.contains('demand')) {
      responseText =
          "☕ **Agro-Commodity Market Intelligence**:\n"
          "• **Robusta Global Trend**: Robust supply tightness in Southeast Asia is driving spot prices above \$3,800/MT.\n"
          "• **Value-Add Opportunity**: Shifting from commercial grade to fine robusta honey/anaerobic natural processing commands a +45% premium in export contracts.";
      nextSuggestions = ['Open Currency Converter', 'Set Robusta price alert'];
    } else {
      final defaultReplies = [
        "🤖 **Agro-AI Diagnostic System**:\n"
        "Analyzed query: *\"$prompt\"*.\n\n"
        "• Recommended Practice: Monitor local soil conditions and maintain optimal N-P-K balances.\n"
        "• Security: Verify crop certification on the blockchain ledger.\n"
        "• Tip: You can ask specific questions about crop diseases, irrigation, market rates, or sensor calibration.",
        "🤖 **Agro-Intelligence Summary**:\n"
        "Regarding *\"$prompt\"*, optimal agronomic practices indicate standard crop rotation combined with IoT environmental telemetry will maximize yield resilience.",
      ];
      responseText = defaultReplies[Random().nextInt(defaultReplies.length)];
      nextSuggestions = quickPromptSuggestions.sublist(0, 3);
    }

    final reply = ChatMessage(
      id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
      text: responseText,
      isUser: false,
      suggestedActions: nextSuggestions,
    );

    addMessage(reply);
    return reply;
  }
}
