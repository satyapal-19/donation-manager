import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/donation_model.dart';
import '../../services/donation_service.dart';
import '../../services/export_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_helpers.dart';
import '../../widgets/common_widgets.dart';
import 'add_donation_screen.dart';

class DonationsScreen extends StatefulWidget {
  final UserModel user;
  const DonationsScreen({super.key, required this.user});
  @override
  State<DonationsScreen> createState() => _DonationsScreenState();
}

class _DonationsScreenState extends State<DonationsScreen> {
  final _donationService = DonationService();
  final _exportService = ExportService();
  late final Stream<List<DonationModel>> _donationsStream;

  String _sortBy = 'newest';
  String _filterType = 'सर्व';
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    // Stable stream: IndexedStack rebuilds all tabs; a new stream each build resets StreamBuilder (flicker).
    _donationsStream = _donationService.streamAllDonations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('देणगी यादी'),
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryDark, AppTheme.primary],
            ),
          ),
        ),
        actions: [
          if (_isExporting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.download_outlined, color: Colors.white),
              onSelected: (v) async {
                setState(() => _isExporting = true);
                try {
                  final donations =
                      await _donationService.streamAllDonations().first;
                  if (v == 'pdf') {
                    await _exportService.exportDonationsPDF(donations);
                  } else {
                    await _exportService.exportDonationsCSV(donations);
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isExporting = false);
                  }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'pdf', child: Text('PDF डाउनलोड')),
                PopupMenuItem(value: 'csv', child: Text('Excel/CSV डाउनलोड')),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<List<DonationModel>>(
              stream: _donationsStream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.primary));
                }
                if (!snap.hasData || snap.data!.isEmpty) {
                  return const EmptyState(
                      message: 'अजून कोणतीही देणगी नाही',
                      icon: Icons.volunteer_activism_outlined);
                }
                var donations = snap.data!;

                // Filter
                if (_filterType != 'सर्व') {
                  donations =
                      donations.where((d) => d.type == _filterType).toList();
                }

                // Sort
                if (_sortBy == 'amount_high') {
                  donations.sort((a, b) => b.amount.compareTo(a.amount));
                } else if (_sortBy == 'amount_low') {
                  donations.sort((a, b) => a.amount.compareTo(b.amount));
                }

                final total = donations.fold<double>(0, (s, d) => s + d.amount);

                return Column(
                  children: [
                    _buildTotalBanner(total, donations.length),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: donations.length,
                        itemBuilder: (_, i) => _DonationCard(
                          donation: donations[i],
                          user: widget.user,
                          donationService: _donationService,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AddDonationScreen(user: widget.user))),
        icon: const Icon(Icons.add),
        label: const Text('देणगी जोडा'),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['सर्व', 'रोख', 'ऑनलाइन', 'वस्तू'].map((type) {
                  final selected = _filterType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(type),
                      selected: selected,
                      onSelected: (_) => setState(() => _filterType = type),
                      backgroundColor: Colors.grey[100],
                      selectedColor: AppTheme.primary.withOpacity(0.2),
                      labelStyle: TextStyle(
                          color: selected
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: AppTheme.primary),
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'newest', child: Text('नवीनतम प्रथम')),
              PopupMenuItem(
                  value: 'amount_high', child: Text('रक्कम जास्त ते कमी')),
              PopupMenuItem(
                  value: 'amount_low', child: Text('रक्कम कमी ते जास्त')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBanner(double total, int count) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppTheme.primaryDark, AppTheme.primary]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.volunteer_activism, color: Colors.white),
          const SizedBox(width: 8),
          Text('$count देणग्या',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Text(AppHelpers.formatCurrency(total),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _DonationCard extends StatelessWidget {
  final DonationModel donation;
  final UserModel user;
  final DonationService donationService;

  const _DonationCard({
    required this.donation,
    required this.user,
    required this.donationService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.primary.withOpacity(0.15),
                  child: Text(
                    donation.donorName.isNotEmpty
                        ? donation.donorName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(donation.donorName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(donation.village,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AmountText(amount: donation.amount, fontSize: 17),
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _typeColor(donation.type).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(donation.type,
                          style: TextStyle(
                              fontSize: 11,
                              color: _typeColor(donation.type),
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                _chip(
                    Icons.flag_outlined, donation.purpose, AppTheme.secondary),
                const SizedBox(width: 8),
                _chip(
                    Icons.calendar_today_outlined,
                    AppHelpers.formatDate(donation.createdAt),
                    AppTheme.textSecondary),
                const Spacer(),
                if (user.isAdmin) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 18, color: AppTheme.primary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => AddDonationScreen(
                                user: user, existingDonation: donation))),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: AppTheme.error),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () async {
                      final confirm = await AppHelpers.showConfirmDialog(
                          context,
                          title: 'देणगी हटवा',
                          message: 'ही देणगी कायमची हटवायची आहे का?',
                          isDestructive: true);
                      if (confirm) {
                        await donationService.deleteDonation(donation.id);
                      }
                    },
                  ),
                ],
              ],
            ),
            if (donation.itemDescription != null &&
                donation.itemDescription!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('वस्तू: ${donation.itemDescription}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'रोख':
        return AppTheme.success;
      case 'ऑनलाइन':
        return Colors.blue;
      case 'वस्तू':
        return AppTheme.secondary;
      default:
        return AppTheme.textSecondary;
    }
  }
}
