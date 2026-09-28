import 'package:flutter/material.dart';
import '../../core/repositories/crop_repository.dart';
import '../../core/session/session_manager.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/crop_model.dart';
import '../blockchain/blockchain_service.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;
  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserModel? _currentUser;
  List<CropModel> _crops = [];
  bool _isLoading = true;
  final _cropRepo = CropRepository();
  final _blockchainService = BlockchainLedgerService();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final user = await SessionManager.instance.getCurrentUser();
    final crops = await _cropRepo.getAllCrops();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _crops = crops;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalArea = _crops.fold<double>(0.0, (sum, c) => sum + c.landAreaHa);
    final totalYield = _crops.fold<double>(0.0, (sum, c) => sum + c.expectedYieldTon);
    final chainLength = _blockchainService.chain.length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agro Dashboard',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: isDark ? Colors.white : const Color(0xFF1B5E20),
              ),
            ),
            Text(
              'Welcome, ${_currentUser?.fullName ?? "Farmer"}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Dashboard',
            onPressed: _loadDashboardData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Hero Token / Wallet Card
                    _buildWalletHeroCard(isDark),

                    const SizedBox(height: 20),

                    // Quick Stats Grid
                    const Text(
                      'Live Farm Statistics',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Active Crops',
                            value: '${_crops.length}',
                            unit: 'Parcels',
                            icon: Icons.grass_rounded,
                            color: const Color(0xFF2E7D32),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Total Land',
                            value: totalArea.toStringAsFixed(1),
                            unit: 'Hectares',
                            icon: Icons.landscape_rounded,
                            color: const Color(0xFF00796B),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Est. Harvest',
                            value: totalYield.toStringAsFixed(1),
                            unit: 'Tons',
                            icon: Icons.inventory_2_outlined,
                            color: const Color(0xFFE65100),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Blockchain Blocks',
                            value: '$chainLength',
                            unit: 'Verified',
                            icon: Icons.link_rounded,
                            color: const Color(0xFF6A1B9A),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Quick Action Shortcuts
                    const Text(
                      'Quick Actions',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildActionButton(
                          icon: Icons.add_circle_outline_rounded,
                          label: 'Add Crop',
                          color: AppTheme.primaryGreen,
                          onTap: () => widget.onNavigateTab?.call(1),
                        ),
                        _buildActionButton(
                          icon: Icons.currency_exchange_rounded,
                          label: 'Rates',
                          color: const Color(0xFF0288D1),
                          onTap: () => widget.onNavigateTab?.call(2),
                        ),
                        _buildActionButton(
                          icon: Icons.explore_rounded,
                          label: 'Sensors / GPS',
                          color: const Color(0xFFE65100),
                          onTap: () => widget.onNavigateTab?.call(2),
                        ),
                        _buildActionButton(
                          icon: Icons.smart_toy_rounded,
                          label: 'AI Helper',
                          color: const Color(0xFF8E24AA),
                          onTap: () => widget.onNavigateTab?.call(3),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Market & Crypto Live Info
                    const Text(
                      'Market & Commodity Tickers',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildMarketCard(
                      symbol: 'AGRO / USDT',
                      name: 'Smart Agro Network Token',
                      price: '\$2.48',
                      change: '+5.82%',
                      isPositive: true,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildMarketCard(
                      symbol: 'SOL / USD',
                      name: 'Solana Native Agro Ledger',
                      price: '\$145.20',
                      change: '+3.14%',
                      isPositive: true,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildMarketCard(
                      symbol: 'CORN / BSH',
                      name: 'Global Organic Sweet Corn',
                      price: '\$4.35',
                      change: '-0.75%',
                      isPositive: false,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 24),

                    // Recent Farm Parcels summary
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Parcels',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () => widget.onNavigateTab?.call(1),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    if (_crops.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2621) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.eco_outlined, size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            const Text(
                              'No crops registered yet.',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => widget.onNavigateTab?.call(1),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add First Crop'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: _crops.take(3).map((crop) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryGreen.withOpacity(0.15),
                                child: const Icon(Icons.spa_rounded, color: AppTheme.primaryGreen),
                              ),
                              title: Text(
                                crop.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${crop.variety} • ${crop.landAreaHa} Ha • Exp: ${crop.expectedYieldTon} T',
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(crop.status).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  crop.status.toUpperCase(),
                                  style: TextStyle(
                                    color: _getStatusColor(crop.status),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'growing':
        return Colors.green;
      case 'harvest_ready':
        return Colors.amber.shade800;
      case 'harvested':
        return Colors.blue;
      case 'diseased':
        return Colors.red;
      default:
        return Colors.teal;
    }
  }

  Widget _buildWalletHeroCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF004D40), Color(0xFF0D532B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.35),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.token_rounded, color: AppTheme.cryptoGold, size: 20),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Smart Agro Wallet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _currentUser?.role.toUpperCase() ?? 'FARMER',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'TOTAL BALANCE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                (_currentUser?.cryptoBalance ?? 100.0).toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'AGRO',
                style: TextStyle(
                  color: AppTheme.cryptoGold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '≈ \$${((_currentUser?.cryptoBalance ?? 100.0) * 2.48).toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentUser?.walletAddress ?? '0x71CAgroRootNode99x0102',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2621) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketCard({
    required String symbol,
    required String name,
    required String price,
    required String change,
    required bool isPositive,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2621) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isPositive ? Colors.green : Colors.red).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: isPositive ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  symbol,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                change,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
