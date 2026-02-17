import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/verification_log.dart';
import '../services/verification_api_service.dart';

class VerificationLogsScreen extends StatefulWidget {
  const VerificationLogsScreen({super.key});

  @override
  State<VerificationLogsScreen> createState() => _VerificationLogsScreenState();
}

class _VerificationLogsScreenState extends State<VerificationLogsScreen> {
  final _verificationApiService = VerificationApiService();
  final _searchController = TextEditingController();
  List<VerificationLog> _allLogs = [];
  List<VerificationLog> _filteredLogs = [];
  String _statusFilter = 'all'; // 'all', 'real', 'fake', 'expired'
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final logs = await _verificationApiService.getVerificationLogs();
      setState(() {
        _allLogs = logs;
        _filteredLogs = logs;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      final query = _searchController.text.toLowerCase();
      _filteredLogs = _allLogs.where((log) {
        final matchesSearch = log.licenseId.toLowerCase().contains(query);

        bool matchesStatus = true;
        if (_statusFilter == 'real') {
          matchesStatus = log.isReal && (log.isActive ?? false);
        } else if (_statusFilter == 'fake') {
          matchesStatus = !log.isReal;
        } else if (_statusFilter == 'expired') {
          matchesStatus = log.isReal && !(log.isActive ?? false);
        }

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Future<void> _exportData() async {
    setState(() => _isLoading = true);

    try {
      final csvData = await _verificationApiService.exportLogs();
      setState(() => _isLoading = false);

      if (csvData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to export data'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Save to app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/VerificationLogs_$timestamp.csv');
      await file.writeAsString(csvData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to: ${file.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
              Colors.blueGrey.shade800,
              Colors.blueGrey.shade700,
              const Color(0xFFF8FAFC),
            ],
            stops: const [0.0, 0.15, 0.15],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    FadeInLeft(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FadeIn(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verification History',
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Audit log of all license checks',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    FadeInRight(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: _exportData,
                          icon: const Icon(
                            Icons.ios_share_rounded,
                            color: Colors.white,
                          ),
                          tooltip: 'Export CSV',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search and Filters
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => _applyFilters(),
                          style: GoogleFonts.outfit(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search license ID or driver...',
                            hintStyle: GoogleFonts.outfit(
                              color: Colors.blueGrey.shade200,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              size: 20,
                              color: Colors.blueGrey.shade400,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: PopupMenuButton<String>(
                        icon: Icon(
                          Icons.filter_list_rounded,
                          color: Colors.blueGrey.shade800,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        onSelected: (value) {
                          setState(() => _statusFilter = value);
                          _applyFilters();
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'all',
                            child: Text(
                              'All Logs',
                              style: GoogleFonts.outfit(),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'real',
                            child: Text(
                              'Verified Real',
                              style: GoogleFonts.outfit(),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'expired',
                            child: Text(
                              'Expired Only',
                              style: GoogleFonts.outfit(),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'fake',
                            child: Text(
                              'Fake Only',
                              style: GoogleFonts.outfit(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Logs List
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Colors.blueGrey.shade800,
                        ),
                      )
                    : _filteredLogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No matching logs found',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLogs,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _filteredLogs.length,
                          itemBuilder: (context, index) {
                            final log = _filteredLogs[index];
                            return FadeInUp(
                              delay: Duration(milliseconds: index * 20),
                              child: _LogCard(log: log),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final VerificationLog log;

  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final isReal = log.isReal;
    final isActive = log.isActive ?? false;

    Color statusColor = Colors.red;
    IconData statusIcon = Icons.error_outline_rounded;
    String statusText = 'FAKE LICENSE';

    if (isReal) {
      if (isActive) {
        statusColor = Colors.teal;
        statusIcon = Icons.check_circle_outline_rounded;
        statusText = 'VERIFIED REAL';
      } else {
        statusColor = Colors.orange;
        statusIcon = Icons.event_busy_rounded;
        statusText = 'REAL BUT EXPIRED';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'License: ${log.licenseId}',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat('HH:mm').format(log.timestamp),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMM dd, yyyy').format(log.timestamp),
                      style: GoogleFonts.outfit(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                    if (log.checkedByUsername != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            log.checkedByUsername!,
                            style: GoogleFonts.outfit(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.outfit(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
