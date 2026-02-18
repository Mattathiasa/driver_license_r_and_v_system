import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/driver.dart';
import '../services/driver_api_service.dart';

class AllDriversScreen extends StatefulWidget {
  const AllDriversScreen({super.key});

  @override
  State<AllDriversScreen> createState() => _AllDriversScreenState();
}

class _AllDriversScreenState extends State<AllDriversScreen> {
  final _driverApiService = DriverApiService();
  final _searchController = TextEditingController();

  List<Driver> _allDrivers = [];
  List<Driver> _filteredDrivers = [];
  bool _isLoading = true;
  String _sortBy = 'name'; // 'name', 'date', 'status'
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDrivers() async {
    setState(() => _isLoading = true);

    final drivers = await _driverApiService.getAllDrivers();

    setState(() {
      _allDrivers = drivers;
      _filteredDrivers = drivers;
      _isLoading = false;
    });

    _applySorting();
  }

  void _filterDrivers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDrivers = _allDrivers;
      } else {
        _filteredDrivers = _allDrivers.where((driver) {
          return driver.fullName.toLowerCase().contains(query.toLowerCase()) ||
              driver.licenseId.toLowerCase().contains(query.toLowerCase()) ||
              driver.licenseType.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
    _applySorting();
  }

  void _applySorting() {
    setState(() {
      switch (_sortBy) {
        case 'name':
          _filteredDrivers.sort(
            (a, b) => _sortAscending
                ? a.fullName.compareTo(b.fullName)
                : b.fullName.compareTo(a.fullName),
          );
          break;
        case 'date':
          _filteredDrivers.sort(
            (a, b) => _sortAscending
                ? a.registeredAt.compareTo(b.registeredAt)
                : b.registeredAt.compareTo(a.registeredAt),
          );
          break;
        case 'status':
          _filteredDrivers.sort(
            (a, b) => _sortAscending
                ? a.status.compareTo(b.status)
                : b.status.compareTo(a.status),
          );
          break;
      }
    });
  }

  void _changeSorting(String sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = sortBy;
        _sortAscending = true;
      }
    });
    _applySorting();
  }

  void _showDriverDetails(Driver driver) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.amber.shade400,
                            Colors.amber.shade700,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          driver.fullName.isNotEmpty
                              ? driver.fullName[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Driver Details',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                _DetailRow(label: 'Driver ID', value: driver.id),
                _DetailRow(label: 'License ID', value: driver.licenseId),
                _DetailRow(label: 'Full Name', value: driver.fullName),
                _DetailRow(
                  label: 'License Type (Grade)',
                  value: 'Class ${driver.licenseType}',
                ),
                _DetailRow(label: 'Expiry Date', value: driver.expiryDate),
                if (driver.qrData != null)
                  _DetailRow(label: 'QR Raw Data', value: driver.qrData!),
                if (driver.ocrRawText != null)
                  _DetailRow(label: 'OCR Raw Text', value: driver.ocrRawText!),
                _DetailRow(
                  label: 'Created Date',
                  value: _formatDateTime(driver.registeredAt),
                ),
                _DetailRow(label: 'Registered By', value: driver.registeredBy),

                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey.shade900,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Close Details',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
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
              Colors.amber.shade700,
              Colors.amber.shade600,
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
                              'Driver Database',
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Registry of all issued licenses',
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
                        child: PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.tune_rounded,
                            color: Colors.white,
                          ),
                          onSelected: _changeSorting,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          itemBuilder: (context) => [
                            _buildPopupItem(
                              'name',
                              Icons.sort_by_alpha_rounded,
                              'Sort by Name',
                            ),
                            _buildPopupItem(
                              'date',
                              Icons.calendar_today_rounded,
                              'Sort by Date',
                            ),
                            _buildPopupItem(
                              'status',
                              Icons.info_outline_rounded,
                              'Sort by Status',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.outfit(),
                    decoration: InputDecoration(
                      hintText: 'Search by name or license ID...',
                      hintStyle: GoogleFonts.outfit(
                        color: Colors.blueGrey.shade200,
                        fontSize: 15,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.amber.shade700,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _filterDrivers('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    onChanged: _filterDrivers,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Results Count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    FadeIn(
                      delay: const Duration(milliseconds: 200),
                      child: Text(
                        '${_filteredDrivers.length} Registry Entry Found',
                        style: GoogleFonts.outfit(
                          color: Colors.blueGrey.shade400,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Drivers List
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Colors.amber.shade700,
                        ),
                      )
                    : _filteredDrivers.isEmpty
                    ? Center(
                        child: FadeIn(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person_search_rounded,
                                  size: 64,
                                  color: Colors.blueGrey.shade200,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                _searchController.text.isEmpty
                                    ? 'No drivers registered'
                                    : 'No matching results',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  color: Colors.blueGrey.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchController.text.isEmpty
                                    ? 'Start by adding a new license'
                                    : 'Try a different search term',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: Colors.blueGrey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadDrivers,
                        color: Colors.amber.shade700,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          itemCount: _filteredDrivers.length,
                          itemBuilder: (context, index) {
                            return FadeInUp(
                              delay: Duration(milliseconds: 50 * index),
                              child: _DriverCard(
                                driver: _filteredDrivers[index],
                                onTap: () =>
                                    _showDriverDetails(_filteredDrivers[index]),
                              ),
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

  PopupMenuItem<String> _buildPopupItem(
    String value,
    IconData icon,
    String text,
  ) {
    final isSelected = _sortBy == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            isSelected
                ? (_sortAscending
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded)
                : icon,
            size: 20,
            color: isSelected
                ? Colors.amber.shade700
                : Colors.blueGrey.shade300,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.outfit(
              color: isSelected
                  ? Colors.amber.shade900
                  : Colors.blueGrey.shade700,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  final Driver driver;
  final VoidCallback onTap;

  const _DriverCard({required this.driver, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.amber.shade400, Colors.amber.shade700],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      driver.fullName.isNotEmpty
                          ? driver.fullName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.fullName,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        driver.licenseId,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.blueGrey.shade400,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _StatusBadge(status: driver.status),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
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

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status.toLowerCase() == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.teal.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.teal.shade100 : Colors.orange.shade100,
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.teal.shade700 : Colors.orange.shade700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.blueGrey.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
