import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/donation_model.dart';
import '../../models/suggestion_model.dart';
import '../../services/auth_service.dart';
import '../../services/donation_service.dart';
import '../../services/other_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_helpers.dart';
import '../../widgets/common_widgets.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  final Function(UserModel) onUserUpdated;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.onUserUpdated,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _authService = AuthService();
  final _donationService = DonationService();
  late final Stream<List<DonationModel>> _myDonationsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _myDonationsStream =
        _donationService.streamUserDonations(widget.user.uid);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    final confirm = await AppHelpers.showConfirmDialog(
      context,
      title: 'लॉगआउट',
      message: 'आपण लॉगआउट करायचे आहे का?',
      isDestructive: true,
    );
    if (confirm) {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('प्रोफाइल'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _signOut,
            tooltip: 'लॉगआउट',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'माहिती'),
            Tab(text: 'माझ्या देणग्या'),
            Tab(text: 'सूचना द्या'),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryDark, AppTheme.primary],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ProfileInfoTab(user: widget.user, authService: _authService,
              onSignOut: _signOut),
          _MyDonationsTab(
            user: widget.user,
            donationsStream: _myDonationsStream,
          ),
          _SuggestionTab(user: widget.user),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// PROFILE INFO TAB
// ─────────────────────────────────────────────────────
class _ProfileInfoTab extends StatelessWidget {
  final UserModel user;
  final AuthService authService;
  final VoidCallback onSignOut;

  const _ProfileInfoTab({
    required this.user,
    required this.authService,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Avatar
          CircleAvatar(
            radius: 46,
            backgroundColor: AppTheme.primary.withOpacity(0.15),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(
                  fontSize: 36,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Text(user.name,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppTheme.primaryDark, AppTheme.primary]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.isAdmin ? '⭐ व्यवस्थापक' : '👤 सदस्य',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          _InfoCard(
            items: [
              _InfoItem(Icons.person_outline, 'नाव', user.name),
              _InfoItem(Icons.phone_outlined, 'मोबाईल', '+91 ${user.mobile}'),
              _InfoItem(
                  Icons.verified_user_outlined,
                  'भूमिका',
                  user.isAdmin ? 'व्यवस्थापक' : 'सदस्य'),
              _InfoItem(
                  Icons.calendar_today_outlined,
                  'नोंदणी दिनांक',
                  AppHelpers.formatDate(user.createdAt)),
            ],
          ),
          const SizedBox(height: 20),
          if (user.isAdmin) ...[
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(
                    context,
                    '/admin',
                    arguments: user,
                  ),
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('व्यवस्थापक पॅनेल'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout, color: AppTheme.error),
            label: const Text('लॉगआउट',
                style: TextStyle(color: AppTheme.error)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.error),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<_InfoItem> items;
  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppTheme.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(item.icon, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.label,
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11)),
                        Text(item.value,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                      ],
                    ),
                  ],
                ),
              ),
              if (i < items.length - 1)
                const Divider(height: 1, indent: 48),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  _InfoItem(this.icon, this.label, this.value);
}

// ─────────────────────────────────────────────────────
// MY DONATIONS TAB (3 years, grouped by year)
// ─────────────────────────────────────────────────────
class _MyDonationsTab extends StatelessWidget {
  final UserModel user;
  final Stream<List<DonationModel>> donationsStream;

  const _MyDonationsTab({
    required this.user,
    required this.donationsStream,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DonationModel>>(
      stream: donationsStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary));
        }
        if (!snap.hasData || snap.data!.isEmpty) {
          return const EmptyState(
              message: 'गेल्या ३ वर्षांत कोणतीही देणगी नाही',
              icon: Icons.volunteer_activism_outlined);
        }

        final donations = snap.data!;
        final grouped = <int, List<DonationModel>>{};
        for (var d in donations) {
          grouped.putIfAbsent(d.createdAt.year, () => []).add(d);
        }
        final years = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: years.length,
          itemBuilder: (_, i) {
            final year = years[i];
            final yearDonations = grouped[year]!;
            final yearTotal = yearDonations.fold<double>(
                0, (s, d) => s + d.amount);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text('$year',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                              fontSize: 15)),
                      const Spacer(),
                      Text(
                          '${yearDonations.length} देणग्या • ${AppHelpers.formatCurrency(yearTotal)}',
                          style: const TextStyle(
                              color: AppTheme.primary, fontSize: 12)),
                    ],
                  ),
                ),
                ...yearDonations.map((d) => Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        dense: true,
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.volunteer_activism,
                              size: 18, color: AppTheme.success),
                        ),
                        title: Text(d.donorName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        subtitle: Text(
                            '${d.type} • ${AppHelpers.formatDate(d.createdAt)}',
                            style: const TextStyle(fontSize: 11)),
                        trailing: AmountText(
                            amount: d.amount,
                            fontSize: 14,
                            color: AppTheme.success),
                      ),
                    )),
                const SizedBox(height: 12),
              ],
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────
// SUGGESTION TAB
// ─────────────────────────────────────────────────────
class _SuggestionTab extends StatefulWidget {
  final UserModel user;
  const _SuggestionTab({required this.user});
  @override
  State<_SuggestionTab> createState() => _SuggestionTabState();
}

class _SuggestionTabState extends State<_SuggestionTab> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  late final Stream<List<SuggestionModel>> _suggestionsStream;

  @override
  void initState() {
    super.initState();
    _suggestionsStream =
        SuggestionService().streamUserSuggestions(widget.user.uid);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) {
      AppHelpers.showToast('सूचना टाका', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await SuggestionService().submitSuggestion(SuggestionModel(
        id: '',
        userId: widget.user.uid,
        userName: widget.user.name,
        text: _controller.text.trim(),
        createdAt: DateTime.now(),
      ));
      _controller.clear();
      AppHelpers.showToast('सूचना पाठवली ✓');
    } catch (e) {
      AppHelpers.showToast('चूक: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppTheme.secondary.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppTheme.secondary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'आपल्या सूचना फक्त व्यवस्थापकांना दिसतात',
                    style:
                        TextStyle(color: AppTheme.secondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'आपली सूचना लिहा',
              hintText:
                  'कार्यक्रम, व्यवस्था, किंवा इतर कोणतीही सूचना...',
              prefixIcon: Icon(Icons.edit_note, color: AppTheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          GradientButton(
            text: 'सूचना पाठवा',
            icon: Icons.send_outlined,
            isLoading: _isLoading,
            onPressed: _submit,
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'माझ्या सूचना'),
          StreamBuilder<List<SuggestionModel>>(
            stream: _suggestionsStream,
            builder: (context, snap) {
              if (!snap.hasData || snap.data!.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('अजून कोणत्याही सूचना नाहीत',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: AppTheme.textSecondary)),
                );
              }
              return Column(
                children: snap.data!.map((s) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.lightbulb,
                          color: AppTheme.secondary),
                      title: Text(s.text,
                          style: const TextStyle(fontSize: 13)),
                      subtitle: Text(
                          AppHelpers.formatDate(s.createdAt),
                          style: const TextStyle(fontSize: 11)),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
