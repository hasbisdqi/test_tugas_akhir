import 'package:flutter/material.dart';
import '../../core/session/session_manager.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';

class ProfileFeedbackScreen extends StatefulWidget {
  final VoidCallback? onThemeToggle;
  const ProfileFeedbackScreen({super.key, this.onThemeToggle});

  @override
  State<ProfileFeedbackScreen> createState() => _ProfileFeedbackScreenState();
}

class _ProfileFeedbackScreenState extends State<ProfileFeedbackScreen> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = await SessionManager.instance.getCurrentUser();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out and clear the active session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SessionManager.instance.clearSession();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Academic Info'),
        actions: [
          if (widget.onThemeToggle != null)
            IconButton(
              icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
              tooltip: 'Toggle Theme',
              onPressed: widget.onThemeToggle,
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Header Card
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primaryGreen, width: 3),
                          ),
                          child: const CircleAvatar(
                            radius: 46,
                            backgroundColor: Color(0xFFE8F5E9),
                            child: Icon(Icons.person, size: 56, color: AppTheme.primaryGreen),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Hasbi',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'NIM: 124240135 • SI UPNYK 24',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // User Account Summary Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account Details',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const Divider(height: 20),
                          _buildInfoRow('Username', _user?.username ?? 'admin'),
                          _buildInfoRow('Email', _user?.email ?? 'admin@smartagro.io'),
                          _buildInfoRow('Role', _user?.role.toUpperCase() ?? 'FARMER / ADMIN'),
                          _buildInfoRow('Token Balance', '${(_user?.cryptoBalance ?? 100.0).toStringAsFixed(2)} AGRO'),
                          _buildInfoRow(
                            'Wallet Address',
                            _user?.walletAddress ?? '0x71CAgroRootNode99x0102',
                            isMono: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Academic Course Feedback Card (Kesan & Pesan)
                  Card(
                    color: isDark ? const Color(0xFF1B2C20) : const Color(0xFFF1F8E9),
                    child: const Padding(
                      padding: EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.school_rounded, color: AppTheme.primaryGreen),
                              SizedBox(width: 8),
                              Text(
                                'Saran & Kesan Mata Kuliah',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Pemrograman Aplikasi Mobile (PAM)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                          ),
                          Divider(height: 20),

                          // Kesan
                          Text(
                            'Kesan:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Mata kuliah Pemrograman Aplikasi Mobile memberikan pemahaman mendalam mengenai arsitektur modern Flutter, manajemen state, integrasi sensor hardware, enkripsi keamanan, dan interaksi database lokal.',
                            style: TextStyle(fontSize: 13, height: 1.4),
                          ),
                          SizedBox(height: 14),

                          // Saran
                          Text(
                            'Saran:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Semoga materi praktikum terus diperkaya dengan studi kasus teknologi terkini seperti AI on-device, Web3 decentralization, dan arsitektur enterprise clean architecture.',
                            style: TextStyle(fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Logout Action Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.exit_to_app_rounded),
                    label: const Text('LOGOUT FROM AGRO SYSTEM'),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFamily: isMono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
