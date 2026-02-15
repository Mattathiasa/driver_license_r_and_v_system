import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_api_service.dart';
import '../services/verification_api_service.dart';
import 'welcome_screen.dart';
import 'scan_license_screen.dart';
import 'register_driver_screen.dart';
import 'verify_license_screen.dart';
import 'all_drivers_screen.dart';
import 'verification_logs_screen.dart';
import 'qr_scanner_screen.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _verificationApiService = VerificationApiService();
  final _authApiService = AuthApiService();
  String? _username;
  Map<String, dynamic> _statistics = {
    'totalDrivers': 0,
    'activeDrivers': 0,
    'expiredDrivers': 0,
  };
  List<dynamic> _recentLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final isLoggedIn = await _authApiService.isLoggedIn();
      if (!isLoggedIn) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            (route) => false,
          );
        }
        return;
      }

      final stats = await _verificationApiService.getDashboardStats();
      final logs = await _verificationApiService.getVerificationLogs();
      final username = await _authApiService.getUsername();

      setState(() {
        _username = username ?? "Administrator";
        _statistics = stats;
        _recentLogs = logs.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Logout',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Logout', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authApiService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
      }
    }
  }

  void _navigateToScreen(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
    // Reload data when returning from other screens
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade800,
              const Color(0xFFF8FAFC),
            ],
            stops: const [0.0, 0.25, 0.25],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  FadeInLeft(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Welcome back,',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _username ?? 'Administrator',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  FadeInRight(
                                    child: Row(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: IconButton(
                                            onPressed: () {
                                              NotificationService()
                                                  .showNotification(
                                                    title: 'System Update',
                                                    body:
                                                        'Database sync completed successfully.',
                                                  );
                                            },
                                            icon: const Icon(
                                              Icons
                                                  .notifications_active_rounded,
                                              color: Colors.white,
                                            ),
                                            tooltip: 'Notifications',
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: IconButton(
                                            onPressed: _handleLogout,
                                            icon: const Icon(
                                              Icons.logout_rounded,
                                              color: Colors.white,
                                            ),
                                            tooltip: 'Logout',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),

                              // Statistics Cards
                              Row(
                                children: [
                                  Expanded(
                                    child: FadeInUp(
                                      delay: const Duration(milliseconds: 100),
                                      child: _StatCard(
                                        title: 'Drivers',
                                        value: _statistics['totalDrivers']
                                            .toString(),
                                        icon: Icons.people_alt_rounded,
                                        color: Colors.white,
                                        textColor: Colors.blue.shade900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: FadeInUp(
                                      delay: const Duration(milliseconds: 200),
                                      child: _StatCard(
                                        title: 'Active',
                                        value: _statistics['activeDrivers']
                                            .toString(),
                                        icon: Icons.verified_rounded,
                                        color: Colors.teal.shade400,
                                        textColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: FadeInUp(
                                      delay: const Duration(milliseconds: 300),
                                      child: _StatCard(
                                        title: 'Expired',
                                        value: _statistics['expiredDrivers']
                                            .toString(),
                                        icon: Icons.warning_amber_rounded,
                                        color: Colors.orange.shade400,
                                        textColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Main Features
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FadeIn(
                                delay: const Duration(milliseconds: 400),
                                child: Text(
                                  'Administrative Tools',
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey.shade900,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Navigation Cards
                              FadeInUp(
                                delay: const Duration(milliseconds: 500),
                                child: _FeatureCard(
                                  title: 'Scan License (OCR)',
                                  description:
                                      'Extract data using AI recognition',
                                  icon: Icons.document_scanner_rounded,
                                  color: Colors.indigo,
                                  onTap: () => _navigateToScreen(
                                    const ScanLicenseScreen(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              FadeInUp(
                                delay: const Duration(milliseconds: 550),
                                child: _FeatureCard(
                                  title: 'Scan QR Code',
                                  description:
                                      'Quick registration from QR code',
                                  icon: Icons.qr_code_scanner_rounded,
                                  color: Colors.purple,
                                  onTap: () => _navigateToScreen(
                                    const QRScannerScreen(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              FadeInUp(
                                delay: const Duration(milliseconds: 600),
                                child: _FeatureCard(
                                  title: 'Register Driver',
                                  description:
                                      'Issue new digital license records',
                                  icon: Icons.person_add_alt_1_rounded,
                                  color: Colors.blue,
                                  onTap: () => _navigateToScreen(
                                    const RegisterDriverScreen(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              FadeInUp(
                                delay: const Duration(milliseconds: 700),
                                child: _FeatureCard(
                                  title: 'Verify Authenticity',
                                  description: 'Real-time database validation',
                                  icon: Icons.verified_user_rounded,
                                  color: Colors.teal,
                                  onTap: () => _navigateToScreen(
                                    const VerifyLicenseScreen(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              FadeInUp(
                                delay: const Duration(milliseconds: 800),
                                child: _FeatureCard(
                                  title: 'Driver Database',
                                  description: 'Manage all issued licenses',
                                  icon: Icons.folder_shared_rounded,
                                  color: Colors.amber.shade700,
                                  onTap: () => _navigateToScreen(
                                    const AllDriversScreen(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              FadeInUp(
                                delay: const Duration(milliseconds: 900),
                                child: _FeatureCard(
                                  title: 'Audit Logs',
                                  description: 'View all verification history',
                                  icon: Icons.history_rounded,
                                  color: Colors.blueGrey,
                                  onTap: () => _navigateToScreen(
                                    const VerificationLogsScreen(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Recent Verifications Section
                              FadeIn(
                                delay: const Duration(milliseconds: 1000),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Recent Verifications',
                                      style: GoogleFonts.outfit(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey.shade900,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => _navigateToScreen(
                                        const VerificationLogsScreen(),
                                      ),
                                      child: Text(
                                        'View All',
                                        style: GoogleFonts.outfit(
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildRecentVerifications(),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildRecentVerifications() {
    if (_recentLogs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'No recent activity',
            style: GoogleFonts.outfit(color: Colors.blueGrey.shade300),
          ),
        ),
      );
    }

    return Column(
      children: _recentLogs.map((log) {
        final isReal = log.isReal;
        final isActive = log.isActive ?? false;
        Color statusColor = Colors.red;
        if (isReal) {
          statusColor = isActive ? Colors.teal : Colors.orange;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isReal ? Icons.verified_rounded : Icons.gpp_bad_rounded,
                color: statusColor,
                size: 20,
              ),
            ),
            title: Text(
              log.driverName ?? 'Unknown Driver',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              log.licenseId,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.blueGrey.shade400,
              ),
            ),
            trailing: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color textColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: textColor, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.outfit(
              color: textColor.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: color, size: 30),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.blueGrey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.blueGrey.shade200,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
