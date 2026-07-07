import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_helpers.dart';
import '../../widgets/common_widgets.dart';
import 'add_edit_event_screen.dart';

class ScheduleScreen extends StatefulWidget {
  final UserModel user;
  const ScheduleScreen({super.key, required this.user});
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _eventService = EventService();
  bool _isCopyingDayOne = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: AppConstants.saptahDays.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('कार्यक्रम वेळापत्रक'),
        automaticallyImplyLeading: false,
        actions: [
          if (widget.user.isAdmin)
            IconButton(
              tooltip: 'दिवस १ ते सर्व दिवस कॉपी',
              onPressed: _isCopyingDayOne ? null : _copyDayOneToAllDays,
              icon: _isCopyingDayOne
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.copy_all),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: AppConstants.saptahDays
              .map((d) => Tab(text: d))
              .toList(),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryDark, AppTheme.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(8, (i) => _DayEventsList(
          dayNumber: i + 1,
          user: widget.user,
          eventService: _eventService,
        )),
      ),
      floatingActionButton: widget.user.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AddEditEventScreen(
                        user: widget.user,
                        dayNumber: _tabController.index + 1)),
              ),
              icon: const Icon(Icons.add),
              label: const Text('कार्यक्रम जोडा'),
            )
          : null,
    );
  }

  Future<void> _copyDayOneToAllDays() async {
    final mode = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'दिवस १ कॉपी करा',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'दिवस १ चे कार्यक्रम दिवस २ ते ८ मध्ये कसे कॉपी करायचे?',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, 'overwrite'),
                icon: const Icon(Icons.content_paste_go),
                label: const Text('Overwrite: दिवस २-८ बदलून टाका'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, 'append'),
                icon: const Icon(Icons.playlist_add),
                label: const Text('Append only: जुने तसेच ठेवा'),
              ),
            ],
          ),
        ),
      ),
    );
    if (mode == null) return;
    final overwrite = mode == 'overwrite';

    setState(() => _isCopyingDayOne = true);
    try {
      await _eventService.copyDayOneEventsToAllDays(overwrite: overwrite);
      AppHelpers.showToast(overwrite
          ? 'दिवस १ चे कार्यक्रम दिवस २-८ मध्ये बदलून कॉपी झाले ✓'
          : 'दिवस १ चे कार्यक्रम दिवस २-८ मध्ये जोडले गेले ✓');
    } catch (e) {
      AppHelpers.showToast('कॉपी करताना चूक: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isCopyingDayOne = false);
    }
  }
}

class _DayEventsList extends StatelessWidget {
  final int dayNumber;
  final UserModel user;
  final EventService eventService;

  const _DayEventsList({
    required this.dayNumber,
    required this.user,
    required this.eventService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EventModel>>(
      stream: eventService.streamEventsByDay(dayNumber),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary));
        }
        if (!snap.hasData || snap.data!.isEmpty) {
          return EmptyState(
            message: 'दिवस $dayNumber साठी कोणतेही कार्यक्रम नाहीत',
            icon: Icons.event_note_outlined,
            action: user.isAdmin
                ? ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => AddEditEventScreen(
                                user: user, dayNumber: dayNumber))),
                    icon: const Icon(Icons.add),
                    label: const Text('पहिला कार्यक्रम जोडा'),
                  )
                : null,
          );
        }

        final events = snap.data!;
        final now = TimeOfDay.now();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (_, i) {
            final event = events[i];
            final isLive = _isCurrentEvent(event, events, i, now);
            final isUpcoming = _isUpcomingEvent(event, now);
            return _EventCard(
              event: event,
              isLive: isLive,
              isUpcoming: isUpcoming,
              isAdmin: user.isAdmin,
              eventService: eventService,
            );
          },
        );
      },
    );
  }

  bool _isCurrentEvent(EventModel event, List<EventModel> events, int index, TimeOfDay now) {
    final parts = event.time.split(':');
    if (parts.length < 2) return false;
    final eventTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0);
    final eventMinutes = eventTime.hour * 60 + eventTime.minute;
    final nowMinutes = now.hour * 60 + now.minute;

    int nextMinutes = eventMinutes + 120;
    if (index < events.length - 1) {
      final nextParts = events[index + 1].time.split(':');
      if (nextParts.length >= 2) {
        final nextTime = TimeOfDay(
            hour: int.tryParse(nextParts[0]) ?? 0,
            minute: int.tryParse(nextParts[1]) ?? 0);
        nextMinutes = nextTime.hour * 60 + nextTime.minute;
      }
    }
    return nowMinutes >= eventMinutes && nowMinutes < nextMinutes;
  }

  bool _isUpcomingEvent(EventModel event, TimeOfDay now) {
    final parts = event.time.split(':');
    if (parts.length < 2) return false;
    final eventTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0);
    final eventMinutes = eventTime.hour * 60 + eventTime.minute;
    final nowMinutes = now.hour * 60 + now.minute;
    return eventMinutes > nowMinutes && eventMinutes - nowMinutes <= 30;
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final bool isLive;
  final bool isUpcoming;
  final bool isAdmin;
  final EventService eventService;

  const _EventCard({
    required this.event,
    required this.isLive,
    required this.isUpcoming,
    required this.isAdmin,
    required this.eventService,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppTheme.divider;
    if (isLive) borderColor = AppTheme.success;
    if (isUpcoming) borderColor = AppTheme.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isLive ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardShadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isLive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: const BoxDecoration(
                color: AppTheme.success,
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.circle, color: Colors.white, size: 8),
                  SizedBox(width: 6),
                  Text('सध्या सुरू आहे',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            )
          else if (isUpcoming)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: const BoxDecoration(
                color: AppTheme.warning,
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule, color: Colors.white, size: 12),
                  SizedBox(width: 6),
                  Text('लवकरच सुरू होईल',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Time
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    event.time,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.person_outline,
                              size: 13, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(event.maharajName,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13)),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(event.maharajLocation,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                      if (event.description != null && event.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(event.description!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  fontStyle: FontStyle.italic)),
                        ),
                    ],
                  ),
                ),
                // Photo
                AppNetworkImage(
                  url: event.maharajPhotoUrl,
                  width: 56,
                  height: 56,
                  borderRadius: BorderRadius.circular(28),
                  placeholder: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person,
                        color: AppTheme.primary, size: 30),
                  ),
                ),
              ],
            ),
          ),
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => AddEditEventScreen(
                                existingEvent: event,
                                user: UserModel(
                                    uid: '',
                                    name: '',
                                    mobile: '',
                                    role: 'admin',
                                    createdAt: DateTime.now()),
                                dayNumber: event.dayNumber))),
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('बदल', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        minimumSize: Size.zero),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('कार्यक्रम हटवा'),
                          content: Text(
                              '"${event.title}" हटवायचा आहे का?'),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('नाही')),
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.error),
                                child: const Text('हो, हटवा')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await eventService.deleteEvent(event.id);
                      }
                    },
                    icon: const Icon(Icons.delete_outline,
                        size: 14, color: AppTheme.error),
                    label: const Text('हटवा',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.error)),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        minimumSize: Size.zero),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
