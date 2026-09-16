import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/event_model.dart';
import '../../models/mahaprasad_model.dart';
import '../../services/other_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_helpers.dart';
import '../../utils/app_constants.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/upi_qr_dialog.dart';
import '../donations/add_donation_screen.dart';
import '../expenses/expenses_screen.dart';

class HomeScreen extends StatelessWidget {
  final UserModel user;

  /// Switches bottom nav to the expenses tab (index 3).
  final VoidCallback? onOpenExpensesTab;
  final HomePreviewData? previewData;

  const HomeScreen({
    super.key,
    required this.user,
    this.onOpenExpensesTab,
    this.previewData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {},
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(context),
            SliverToBoxAdapter(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'सप्ताह व्यवस्थापक',
          style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl:
                  'https://via.placeholder.com/800x400/FF6F00/FFFFFF?text=हनुमान+मंदिर',
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryDark, AppTheme.primary],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🙏', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 8),
                      Text('हनुमान मंदिर, चिंचोली-भोसे',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_2, color: Colors.white),
          tooltip: 'QR देणगी स्वीकारा',
          onPressed: () => UpiQrDialog.show(context, user: user),
        ),
        if (user.isAdmin)
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
            onPressed: () => Navigator.pushNamed(
              context,
              '/admin',
              arguments: user,
            ),
          ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGreeting(),
        _buildSummarySection(context),
        _buildQuickActions(context),
        _buildTodayEvents(),
        _buildTodayMahaprasad(),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    String emoji;
    if (hour < 12) {
      greeting = 'शुभ प्रभात';
      emoji = '🌅';
    } else if (hour < 17) {
      greeting = 'शुभ दुपार';
      emoji = '☀️';
    } else {
      greeting = 'शुभ संध्याकाळ';
      emoji = '🌆';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$emoji $greeting',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
              ),
              Text(
                '🙏 ${user.name}',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
              ),
            ],
          ),
          const Spacer(),
          if (user.isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.primaryDark, AppTheme.primary]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.star, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text('व्यवस्थापक',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    if (previewData != null) {
      return _buildStaticSummarySection(previewData!);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.donationsCollection)
          .snapshots(),
      builder: (context, donSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(AppConstants.expensesCollection)
              .snapshots(),
          builder: (context, expSnap) {
            double totalDon = 0;
            double totalExp = 0;

            if (donSnap.hasData) {
              for (var doc in donSnap.data!.docs) {
                totalDon += (doc['amount'] ?? 0).toDouble();
              }
            }
            if (expSnap.hasData) {
              for (var doc in expSnap.data!.docs) {
                totalExp += (doc['amount'] ?? 0).toDouble();
              }
            }

            final balance = totalDon - totalExp;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          title: 'एकूण देणगी',
                          amount: AppHelpers.formatCurrency(totalDon),
                          icon: Icons.volunteer_activism,
                          color: AppTheme.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SummaryCard(
                          title: 'एकूण खर्च',
                          amount: AppHelpers.formatCurrency(totalExp),
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
                      gradient: LinearGradient(
                        colors: balance >= 0
                            ? [const Color(0xFF1B5E20), AppTheme.success]
                            : [AppTheme.error, const Color(0xFF8B0000)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet,
                            color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('शिल्लक रक्कम',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            Text(
                              AppHelpers.formatCurrency(balance),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Icon(
                          balance >= 0
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: Colors.white,
                          size: 32,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStaticSummarySection(HomePreviewData data) {
    final balance = data.totalDonations - data.totalExpenses;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  title: 'एकूण देणगी',
                  amount: AppHelpers.formatCurrency(data.totalDonations),
                  icon: Icons.volunteer_activism,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  title: 'एकूण खर्च',
                  amount: AppHelpers.formatCurrency(data.totalExpenses),
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
              gradient: LinearGradient(
                colors: balance >= 0
                    ? [const Color(0xFF1B5E20), AppTheme.success]
                    : [AppTheme.error, const Color(0xFF8B0000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet,
                    color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('शिल्लक रक्कम',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      AppHelpers.formatCurrency(balance),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(
                  balance >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: Colors.white,
                  size: 32,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AddDonationScreen(user: user))),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('देणगी जोडा'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (onOpenExpensesTab != null) {
                      onOpenExpensesTab!();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExpensesScreen(user: user),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: const Text('खर्च पाहा'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => UpiQrDialog.show(context, user: user),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.qr_code_2,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UPI QR कोडद्वारे देणगी स्वीकारा',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'GPay, PhonePe, Paytm द्वारे थेट देणगी',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 14, color: AppTheme.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayEvents() {
    const currentDay = AppConstants.currentSaptahDay;
    if (previewData != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
              title:
                  'आजचे कार्यक्रम (${AppConstants.saptahDays[currentDay - 1]})'),
          if (previewData!.todayEvents.isEmpty)
            EmptyState(
                message:
                    '${AppConstants.saptahDays[currentDay - 1]} साठी कोणतेही कार्यक्रम नाहीत',
                icon: Icons.event_busy)
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: previewData!.todayEvents.length,
              itemBuilder: (_, i) =>
                  _EventTile(event: previewData!.todayEvents[i]),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
            title:
                'आजचे कार्यक्रम (${AppConstants.saptahDays[currentDay - 1]})'),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(AppConstants.eventsCollection)
              .where('dayNumber', isEqualTo: currentDay)
              .orderBy('time')
              .limit(5)
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: Padding(
                      padding: EdgeInsets.all(16),
                      child:
                          CircularProgressIndicator(color: AppTheme.primary)));
            }
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return EmptyState(
                  message:
                      '${AppConstants.saptahDays[currentDay - 1]} साठी कोणतेही कार्यक्रम नाहीत',
                  icon: Icons.event_busy);
            }
            final events = snap.data!.docs
                .map((doc) => EventModel.fromMap(
                    doc.data() as Map<String, dynamic>, doc.id))
                .toList();
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              itemBuilder: (_, i) => _EventTile(event: events[i]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTodayMahaprasad() {
    if (previewData != null) {
      final previewMahaprasad = previewData!.todayMahaprasad;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
              title: 'आजचा महाप्रसाद'),
          if (previewMahaprasad == null)
            const Padding(
              padding: EdgeInsets.all(16),
              child: EmptyState(
                  message:
                      'आजच्या महाप्रसादाची माहिती उपलब्ध नाही',
                  icon: Icons.restaurant_outlined),
            )
          else
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (previewMahaprasad.imageUrl != null)
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      child: CachedNetworkImage(
                        imageUrl: previewMahaprasad.imageUrl!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Text('🍲', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text('महाप्रसाद मेनू',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ]),
                        const SizedBox(height: 8),
                        Text(previewMahaprasad.menuText,
                            style: const TextStyle(fontSize: 14, height: 1.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'आजचा महाप्रसाद'),
        StreamBuilder<MahaprasadModel?>(
          stream: MahaprasadService().streamTodayMahaprasad(),
          builder: (context, snap) {
            if (!snap.hasData || snap.data == null) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: EmptyState(
                    message: 'आजच्या महाप्रसादाची माहिती उपलब्ध नाही',
                    icon: Icons.restaurant_outlined),
              );
            }
            final m = snap.data!;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (m.imageUrl != null)
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      child: CachedNetworkImage(
                        imageUrl: m.imageUrl!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Text('🍚', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text('महाप्रसाद मेनू',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ]),
                        const SizedBox(height: 8),
                        Text(m.menuText,
                            style: const TextStyle(fontSize: 14, height: 1.5)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class HomePreviewData {
  final double totalDonations;
  final double totalExpenses;
  final List<EventModel> todayEvents;
  final MahaprasadModel? todayMahaprasad;

  const HomePreviewData({
    required this.totalDonations,
    required this.totalExpenses,
    required this.todayEvents,
    required this.todayMahaprasad,
  });
}

class _EventTile extends StatelessWidget {
  final EventModel event;
  const _EventTile({required this.event});

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
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              event.time,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text('${event.maharajName} • ${event.maharajLocation}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          AppNetworkImage(
            url: event.maharajPhotoUrl,
            width: 40,
            height: 40,
            borderRadius: BorderRadius.circular(20),
          ),
        ],
      ),
    );
  }
}
