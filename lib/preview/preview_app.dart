import 'package:flutter/material.dart';

import '../models/donation_model.dart';
import '../models/event_model.dart';
import '../theme/app_theme.dart';
import '../utils/app_helpers.dart';
import '../widgets/common_widgets.dart';

class DonationManagerPreviewApp extends StatelessWidget {
  const DonationManagerPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Donation Manager Preview',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routes: {
        '/': (_) => const _PreviewIndexScreen(),
        '/dashboard': (_) => const _PreviewDashboardScreen(),
        '/donations': (_) => const _PreviewDonationsScreen(),
        '/admin': (_) => const _PreviewAdminScreen(),
      },
    );
  }
}

class _PreviewIndexScreen extends StatelessWidget {
  const _PreviewIndexScreen();

  @override
  Widget build(BuildContext context) {
    final previews = [
      (
        title: 'Dashboard',
        subtitle: 'Balance, events, and quick actions',
        route: '/dashboard',
        icon: Icons.dashboard_outlined,
      ),
      (
        title: 'Donations',
        subtitle: 'Donation records, filters, and totals',
        route: '/donations',
        icon: Icons.volunteer_activism_outlined,
      ),
      (
        title: 'Admin Panel',
        subtitle: 'Requests, reports, and admin actions',
        route: '/admin',
        icon: Icons.admin_panel_settings_outlined,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation Manager Preview'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: previews.length,
        itemBuilder: (context, index) {
          final preview = previews[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                child: Icon(preview.icon, color: AppTheme.primary),
              ),
              title: Text(preview.title),
              subtitle: Text(preview.subtitle),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.pushNamed(context, preview.route),
            ),
          );
        },
      ),
    );
  }
}

class _PreviewDashboardScreen extends StatelessWidget {
  const _PreviewDashboardScreen();

  @override
  Widget build(BuildContext context) {
    final totalDonations = _previewDonations.fold<double>(
      0,
      (sum, donation) => sum + donation.amount,
    );
    const totalExpenses = 48230.0;
    final balance = totalDonations - totalExpenses;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Donation Manager',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryDark, AppTheme.primary],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 52),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.volunteer_activism_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Community donations and event operations',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: const [
              Icon(Icons.notifications_outlined, color: Colors.white),
              SizedBox(width: 12),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Aarav Patil',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Spacer(),
                        _PreviewRoleChip(label: 'Admin'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SummaryCard(
                                title: 'Total Donations',
                                amount:
                                    AppHelpers.formatCurrency(totalDonations),
                                icon: Icons.volunteer_activism,
                                color: AppTheme.success,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SummaryCard(
                                title: 'Total Expenses',
                                amount:
                                    AppHelpers.formatCurrency(totalExpenses),
                                icon: Icons.receipt_long,
                                color: AppTheme.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1B5E20), AppTheme.success],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.account_balance_wallet,
                                color: Colors.white,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Available Balance',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    AppHelpers.formatCurrency(balance),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SectionHeader(title: 'Quick Actions'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: const [
                        Expanded(
                          child: _PreviewActionCard(
                            icon: Icons.add_circle_outline,
                            label: 'Add Donation',
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _PreviewActionCard(
                            icon: Icons.receipt_long_outlined,
                            label: 'Expenses',
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _PreviewActionCard(
                            icon: Icons.calendar_month_outlined,
                            label: 'Schedule',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SectionHeader(title: 'Today\'s Schedule'),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _previewEvents.length,
                    itemBuilder: (context, index) =>
                        _PreviewEventTile(event: _previewEvents[index]),
                  ),
                  const SectionHeader(title: 'Today\'s Menu'),
                  Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.restaurant_menu,
                                  color: AppTheme.primary),
                              SizedBox(width: 8),
                              Text(
                                'Mahaprasad Menu',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Khichdi, poori, mixed vegetable sabzi, sweet sheera, and buttermilk.',
                            style: TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewDonationsScreen extends StatelessWidget {
  const _PreviewDonationsScreen();

  @override
  Widget build(BuildContext context) {
    final totalDonations = _previewDonations.fold<double>(
      0,
      (sum, donation) => sum + donation.amount,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donations'),
        actions: const [
          Icon(Icons.download_outlined),
          SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryDark, AppTheme.primary],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Donation Summary',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  AppHelpers.formatCurrency(totalDonations),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_previewDonations.length} entries',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: const [
                _PreviewFilterChip(label: 'All', selected: true),
                SizedBox(width: 8),
                _PreviewFilterChip(label: 'Cash'),
                SizedBox(width: 8),
                _PreviewFilterChip(label: 'Online'),
                SizedBox(width: 8),
                _PreviewFilterChip(label: 'Items'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              itemCount: _previewDonations.length,
              itemBuilder: (context, index) =>
                  _PreviewDonationCard(donation: _previewDonations[index]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Add Donation'),
      ),
    );
  }
}

class _PreviewAdminScreen extends StatelessWidget {
  const _PreviewAdminScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Operations Overview',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(
                child: SummaryCard(
                  title: 'Pending Requests',
                  amount: '07',
                  icon: Icons.pending_actions,
                  color: AppTheme.warning,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  title: 'Notifications',
                  amount: '05',
                  icon: Icons.notifications_active,
                  color: AppTheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SummaryCard(
            title: 'Monthly Reports',
            amount: '12 ready',
            icon: Icons.analytics_outlined,
            color: AppTheme.success,
          ),
          const SizedBox(height: 20),
          const Text(
            'Admin Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const _PreviewAdminTile(
            icon: Icons.receipt_long,
            title: 'Review Expense Requests',
            subtitle: 'Approve or reject submitted requests',
            status: '7 pending',
            color: AppTheme.warning,
          ),
          const _PreviewAdminTile(
            icon: Icons.add_chart,
            title: 'Add Direct Expense',
            subtitle: 'Record an expense without a request',
            status: 'Ready',
            color: AppTheme.primary,
          ),
          const _PreviewAdminTile(
            icon: Icons.notifications_active,
            title: 'Send Notifications',
            subtitle: 'Broadcast announcements to all users',
            status: '5 drafts',
            color: AppTheme.secondary,
          ),
          const _PreviewAdminTile(
            icon: Icons.restaurant,
            title: 'Update Mahaprasad',
            subtitle: 'Publish today\'s menu and meal details',
            status: 'Today',
            color: AppTheme.success,
          ),
          const _PreviewAdminTile(
            icon: Icons.lightbulb_outline,
            title: 'View Suggestions',
            subtitle: 'Check private feedback from members',
            status: '3 new',
            color: Colors.blue,
          ),
        ],
      ),
    );
  }
}

class _PreviewRoleChip extends StatelessWidget {
  final String label;

  const _PreviewRoleChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppTheme.primaryDark, AppTheme.primary]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewActionCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PreviewActionCard({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primary),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _PreviewEventTile extends StatelessWidget {
  final EventModel event;

  const _PreviewEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              event.time,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${event.maharajName} • ${event.maharajLocation}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
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

class _PreviewFilterChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _PreviewFilterChip({
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {},
      backgroundColor: Colors.grey[100],
      selectedColor: AppTheme.primary.withValues(alpha: 0.18),
      labelStyle: TextStyle(
        color: selected ? AppTheme.primary : AppTheme.textSecondary,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _PreviewDonationCard extends StatelessWidget {
  final DonationModel donation;

  const _PreviewDonationCard({required this.donation});

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
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                  child: Text(
                    donation.donorName.isNotEmpty
                        ? donation.donorName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donation.donorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        donation.village,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      donation.amount > 0
                          ? AppHelpers.formatCurrency(donation.amount)
                          : donation.itemDescription ?? 'Items',
                      style: TextStyle(
                        color: donation.amount > 0
                            ? AppTheme.success
                            : AppTheme.secondary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            _typeColor(donation.type).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _typeLabel(donation.type),
                        style: TextStyle(
                          fontSize: 11,
                          color: _typeColor(donation.type),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                _smallMeta(
                  Icons.flag_outlined,
                  _purposeLabel(donation.purpose),
                  AppTheme.secondary,
                ),
                const SizedBox(width: 8),
                _smallMeta(
                  Icons.calendar_today_outlined,
                  AppHelpers.formatDate(donation.createdAt),
                  AppTheme.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallMeta(IconData icon, String label, Color color) {
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

  String _typeLabel(String type) {
    switch (type) {
      case 'रोख':
        return 'Cash';
      case 'ऑनलाइन':
        return 'Online';
      case 'वस्तू':
        return 'Items';
      default:
        return type;
    }
  }

  String _purposeLabel(String purpose) {
    switch (purpose) {
      case 'सामान्य':
        return 'General';
      case 'धर्मकार्य':
        return 'Religious';
      case 'भजने':
        return 'Bhajans';
      case 'महाप्रसाद':
        return 'Mahaprasad';
      case 'विशेष':
        return 'Special';
      default:
        return purpose;
    }
  }
}

class _PreviewAdminTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final Color color;

  const _PreviewAdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

final List<EventModel> _previewEvents = [
  EventModel(
    id: 'event-1',
    dayNumber: 7,
    time: '08:00 AM',
    title: 'Morning Aarti',
    maharajName: 'Shri Ramdas Maharaj',
    maharajLocation: 'Pandharpur',
    maharajPhotoUrl: null,
    description: 'Daily morning prayer and bhajan session.',
    createdAt: DateTime(2026, 7, 7, 8),
  ),
  EventModel(
    id: 'event-2',
    dayNumber: 7,
    time: '11:00 AM',
    title: 'Community Lunch',
    maharajName: 'Volunteer Team',
    maharajLocation: 'Main Hall',
    maharajPhotoUrl: null,
    description: 'Mahaprasad lunch service for all attendees.',
    createdAt: DateTime(2026, 7, 7, 11),
  ),
  EventModel(
    id: 'event-3',
    dayNumber: 7,
    time: '06:30 PM',
    title: 'Evening Kirtan',
    maharajName: 'Sant Tukaram Mandal',
    maharajLocation: 'Temple Stage',
    maharajPhotoUrl: null,
    description: 'Devotional singing and discourse.',
    createdAt: DateTime(2026, 7, 7, 18, 30),
  ),
];

final List<DonationModel> _previewDonations = [
  DonationModel(
    id: 'donation-1',
    donorName: 'Ramesh Kulkarni',
    village: 'Pandharpur',
    amount: 5100,
    type: 'रोख',
    purpose: 'सामान्य',
    proofImageUrl: null,
    addedByUid: 'preview-admin',
    addedByName: 'Aarav Patil',
    createdAt: DateTime(2026, 7, 7, 9, 15),
    itemDescription: null,
  ),
  DonationModel(
    id: 'donation-2',
    donorName: 'Sita Deshmukh',
    village: 'Solapur',
    amount: 2500,
    type: 'ऑनलाइन',
    purpose: 'धर्मकार्य',
    proofImageUrl: null,
    addedByUid: 'preview-admin',
    addedByName: 'Aarav Patil',
    createdAt: DateTime(2026, 7, 6, 20, 30),
    itemDescription: null,
  ),
  DonationModel(
    id: 'donation-3',
    donorName: 'Mahesh Yadav',
    village: 'Barshi',
    amount: 0,
    type: 'वस्तू',
    purpose: 'महाप्रसाद',
    proofImageUrl: null,
    addedByUid: 'preview-admin',
    addedByName: 'Aarav Patil',
    createdAt: DateTime(2026, 7, 6, 18, 20),
    itemDescription: '10 rice bags',
  ),
  DonationModel(
    id: 'donation-4',
    donorName: 'Anjali Patwardhan',
    village: 'Pune',
    amount: 3000,
    type: 'ऑनलाइन',
    purpose: 'विशेष',
    proofImageUrl: null,
    addedByUid: 'preview-admin',
    addedByName: 'Aarav Patil',
    createdAt: DateTime(2026, 7, 5, 10, 30),
    itemDescription: null,
  ),
  DonationModel(
    id: 'donation-5',
    donorName: 'Seva Group',
    village: 'Mumbai',
    amount: 11000,
    type: 'रोख',
    purpose: 'भजने',
    proofImageUrl: null,
    addedByUid: 'preview-admin',
    addedByName: 'Aarav Patil',
    createdAt: DateTime(2026, 7, 4, 17),
    itemDescription: null,
  ),
];
