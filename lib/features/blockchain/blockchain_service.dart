import 'dart:convert';
import 'package:crypto/crypto.dart';

class Block {
  final int index;
  final String timestamp;
  final Map<String, dynamic> data;
  final String previousHash;
  final String hash;
  final int nonce;

  Block({
    required this.index,
    required this.timestamp,
    required this.data,
    required this.previousHash,
    required this.hash,
    required this.nonce,
  });

  static String calculateHash(
    int index,
    String timestamp,
    Map<String, dynamic> data,
    String previousHash,
    int nonce,
  ) {
    final rawData = '$index$timestamp${jsonEncode(data)}$previousHash$nonce';
    return sha256.convert(utf8.encode(rawData)).toString();
  }

  Map<String, dynamic> toMap() {
    return {
      'index': index,
      'timestamp': timestamp,
      'data': data,
      'previousHash': previousHash,
      'hash': hash,
      'nonce': nonce,
    };
  }

  factory Block.fromMap(Map<String, dynamic> map) {
    return Block(
      index: map['index'] as int,
      timestamp: map['timestamp'] as String,
      data: Map<String, dynamic>.from(map['data'] as Map),
      previousHash: map['previousHash'] as String,
      hash: map['hash'] as String,
      nonce: map['nonce'] as int? ?? 0,
    );
  }
}

class BlockchainLedgerService {
  static final BlockchainLedgerService _instance = BlockchainLedgerService._internal();
  factory BlockchainLedgerService() => _instance;
  BlockchainLedgerService._internal() {
    _initChain();
  }

  final List<Block> _chain = [];

  List<Block> get chain => List.unmodifiable(_chain);

  void _initChain() {
    if (_chain.isEmpty) {
      final genesisBlock = _createGenesisBlock();
      _chain.add(genesisBlock);
    }
  }

  Block _createGenesisBlock() {
    final timestamp = DateTime(2025, 1, 1).toIso8601String();
    final data = {
      'action': 'GENESIS_CREATION',
      'item': 'Smart Agro Origin Genesis',
      'farmer': 'Agro System Root',
      'location': 'Agro Farm Hub #001',
      'certificateId': 'AGRO-ROOT-GENESIS-2025',
    };
    final hash = Block.calculateHash(0, timestamp, data, '0' * 64, 0);
    return Block(
      index: 0,
      timestamp: timestamp,
      data: data,
      previousHash: '0' * 64,
      hash: hash,
      nonce: 0,
    );
  }

  Block get latestBlock => _chain.last;

  /// Mines a new block with Proof-of-Work (PoW difficulty of 2 leading zeros '00')
  Future<Block> addRecord({
    required String action,
    required String itemName,
    required String batchNumber,
    required String producerOrOwner,
    required String location,
    required double quantity,
    required String unit,
    Map<String, dynamic>? extraDetails,
  }) async {
    final prevBlock = latestBlock;
    final index = prevBlock.index + 1;
    final timestamp = DateTime.now().toIso8601String();

    final data = {
      'action': action,
      'itemName': itemName,
      'batchNumber': batchNumber,
      'producerOrOwner': producerOrOwner,
      'location': location,
      'quantity': quantity,
      'unit': unit,
      'extra': extraDetails ?? {},
    };

    // Proof of Work simulation (difficulty: hash starting with '00')
    int nonce = 0;
    String hash = Block.calculateHash(index, timestamp, data, prevBlock.hash, nonce);
    while (!hash.startsWith('00')) {
      nonce++;
      hash = Block.calculateHash(index, timestamp, data, prevBlock.hash, nonce);
    }

    final newBlock = Block(
      index: index,
      timestamp: timestamp,
      data: data,
      previousHash: prevBlock.hash,
      hash: hash,
      nonce: nonce,
    );

    _chain.add(newBlock);
    return newBlock;
  }

  /// Verifies entire chain integrity using SHA-256 recalculation
  bool verifyChainIntegrity() {
    for (int i = 1; i < _chain.length; i++) {
      final current = _chain[i];
      final previous = _chain[i - 1];

      if (current.previousHash != previous.hash) {
        return false;
      }

      final recalculated = Block.calculateHash(
        current.index,
        current.timestamp,
        current.data,
        current.previousHash,
        current.nonce,
      );

      if (current.hash != recalculated) {
        return false;
      }
    }
    return true;
  }

  /// Tamper simulation test to prove cryptographic immutability
  void tamperBlock(int index, String tamperedItemName) {
    if (index >= 0 && index < _chain.length) {
      final original = _chain[index];
      final mutatedData = Map<String, dynamic>.from(original.data);
      mutatedData['itemName'] = tamperedItemName;

      // Replace with mutated block (without recalculating hash or next links)
      _chain[index] = Block(
        index: original.index,
        timestamp: original.timestamp,
        data: mutatedData,
        previousHash: original.previousHash,
        hash: original.hash, // Hash now fails verification
        nonce: original.nonce,
      );
    }
  }

  List<Block> searchByBatchOrItem(String query) {
    if (query.trim().isEmpty) return chain;
    final q = query.toLowerCase();
    return _chain.where((b) {
      final item = b.data['itemName']?.toString().toLowerCase() ?? '';
      final batch = b.data['batchNumber']?.toString().toLowerCase() ?? '';
      final farmer = b.data['producerOrOwner']?.toString().toLowerCase() ?? '';
      final action = b.data['action']?.toString().toLowerCase() ?? '';
      return item.contains(q) || batch.contains(q) || farmer.contains(q) || action.contains(q);
    }).toList();
  }
}
