import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../models/expense_request_model.dart';
import '../../models/expense_model.dart';
import '../../models/mahaprasad_model.dart';
import '../../services/expense_service.dart';
import '../../services/other_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_helpers.dart';
import '../../widgets/common_widgets.dart';

// ────────────────────────────────────────────────────────
// ADMIN PANEL MAIN SCREEN
// ────────────────────────────────────────────────────────
class AdminPanelScreen extends StatelessWidget {
  final UserModel user;
  const AdminPanelScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OmAppBar(title: 'व्यवस्थापक पॅनेल'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AdminTile(
            icon: Icons.receipt_long,
            title: 'खर्च विनंत्या',
            subtitle: 'प्रलंबित विनंत्या मंजूर/नाकारा',
            color: AppTheme.error,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AdminExpenseRequestsScreen(user: user))),
          ),
          _AdminTile(
            icon: Icons.add_chart,
            title: 'थेट खर्च जोडा',
            subtitle: 'विनंतीशिवाय खर्च नोंद करा',
            color: AppTheme.warning,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AdminAddDirectExpenseScreen(user: user))),
          ),
          _AdminTile(
            icon: Icons.notifications_active,
            title: 'सूचना पाठवा',
            subtitle: 'सर्व वापरकर्त्यांना सूचना',
            color: Colors.blue,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AdminSendNotificationScreen(user: user))),
          ),
          _AdminTile(
            icon: Icons.restaurant,
            title: 'महाप्रसाद अपडेट',
            subtitle: 'आजचा महाप्रसाद मेनू',
            color: AppTheme.success,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        AdminMahaprasadScreen(user: user))),
          ),
          _AdminTile(
            icon: Icons.lightbulb_outline,
            title: 'सूचना पाहा',
            subtitle: 'वापरकर्त्यांच्या सूचना',
            color: AppTheme.secondary,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AdminSuggestionsScreen(user: user))),
          ),
          _AdminTile(
            icon: Icons.report_problem_outlined,
            title: 'तक्रारी पाहा',
            subtitle: 'देणगी संबंधित तक्रारी',
            color: Colors.deepPurple,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AdminIssuesScreen(user: user))),
          ),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12)),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: color),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
// ADMIN: EXPENSE REQUESTS
// ────────────────────────────────────────────────────────
class AdminExpenseRequestsScreen extends StatefulWidget {
  final UserModel user;
  const AdminExpenseRequestsScreen({super.key, required this.user});
  @override
  State<AdminExpenseRequestsScreen> createState() =>
      _AdminExpenseRequestsScreenState();
}

class _AdminExpenseRequestsScreenState
    extends State<AdminExpenseRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _expenseService = ExpenseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('खर्च विनंत्या'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'प्रलंबित'),
            Tab(text: 'मंजूर'),
            Tab(text: 'नाकारलेले'),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [AppTheme.primaryDark, AppTheme.primary]),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RequestList(
              user: widget.user,
              status: AppConstants.statusPending,
              expenseService: _expenseService),
          _RequestList(
              user: widget.user,
              status: AppConstants.statusApproved,
              expenseService: _expenseService),
          _RequestList(
              user: widget.user,
              status: AppConstants.statusRejected,
              expenseService: _expenseService),
        ],
      ),
    );
  }
}

class _RequestList extends StatefulWidget {
  final UserModel user;
  final String status;
  final ExpenseService expenseService;

  const _RequestList({
    required this.user,
    required this.status,
    required this.expenseService,
  });

  @override
  State<_RequestList> createState() => _RequestListState();
}

class _RequestListState extends State<_RequestList> {
  late Stream<List<ExpenseRequestModel>> _stream;
  List<ExpenseRequestModel> _cachedRequests = const [];

  Stream<List<ExpenseRequestModel>> _buildStream() {
    if (widget.status == AppConstants.statusPending) {
      return widget.expenseService.streamPendingExpenseRequests();
    }
    return widget.expenseService.streamAllExpenseRequests().map(
        (list) => list.where((r) => r.status == widget.status).toList());
  }

  @override
  void initState() {
    super.initState();
    _stream = _buildStream();
  }

  @override
  void didUpdateWidget(covariant _RequestList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _stream = _buildStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ExpenseRequestModel>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasData) {
          _cachedRequests = snap.data!;
        }
        final requests = snap.data ?? _cachedRequests;

        if (snap.connectionState == ConnectionState.waiting &&
            requests.isEmpty) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary));
        }

        if (snap.hasError && requests.isEmpty) {
          return EmptyState(
              message: 'डेटा लोड होत नाही. नेटवर्क/परवानगी तपासा.',
              icon: Icons.wifi_off_outlined);
        }

        if (requests.isEmpty) {
          return EmptyState(
              message:
                  '${AppHelpers.getStatusText(widget.status)} विनंत्या नाहीत',
              icon: Icons.inbox_outlined);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: requests.length,
          itemBuilder: (_, i) => _AdminRequestCard(
            request: requests[i],
            user: widget.user,
            expenseService: widget.expenseService,
          ),
        );
      },
    );
  }
}

class _AdminRequestCard extends StatelessWidget {
  final ExpenseRequestModel request;
  final UserModel user;
  final ExpenseService expenseService;

  const _AdminRequestCard({
    required this.request,
    required this.user,
    required this.expenseService,
  });

  Future<void> _approve(BuildContext context) async {
    final confirm = await AppHelpers.showConfirmDialog(
      context,
      title: 'विनंती मंजूर करा',
      message:
          '"${request.name}" - ${AppHelpers.formatCurrency(request.amount)} ही विनंती मंजूर करायची आहे का?',
      confirmText: 'मंजूर करा',
    );
    if (!confirm) return;

    try {
      await expenseService.approveExpenseRequest(
        requestId: request.id,
        adminUid: user.uid,
        adminName: user.name,
      );
      AppHelpers.showToast('विनंती मंजूर केली ✓');
    } catch (e) {
      AppHelpers.showToast('चूक: $e', isError: true);
    }
  }

  Future<void> _reject(BuildContext context) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('विनंती नाकारा'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('"${request.name}" नाकारण्याचे कारण:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'कारण टाका (ऐच्छिक)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('रद्द करा')),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, reasonController.text),
            style: TextButton.styleFrom(
                foregroundColor: AppTheme.error),
            child: const Text('नाकारा'),
          ),
        ],
      ),
    );

    if (reason == null) return;

    try {
      await expenseService.rejectExpenseRequest(
        requestId: request.id,
        adminUid: user.uid,
        adminName: user.name,
        reason: reason.isNotEmpty ? reason : null,
      );
      AppHelpers.showToast('विनंती नाकारली');
    } catch (e) {
      AppHelpers.showToast('चूक: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                          '${request.userName} • ${AppHelpers.formatDateTime(request.timestamp)}',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                StatusBadge(status: request.status),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                AmountText(
                    amount: request.amount,
                    fontSize: 18,
                    color: AppTheme.error),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                      '${AppHelpers.getCategoryIcon(request.category)} ${request.category}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.primary)),
                ),
              ],
            ),
            if (request.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(request.description,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13)),
            ],
            if (request.imageUrl != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AppNetworkImage(
                  url: request.imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            if (request.isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _reject(context),
                      icon: const Icon(Icons.close, size: 16,
                          color: AppTheme.error),
                      label: const Text('नाकारा',
                          style: TextStyle(color: AppTheme.error)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.error)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approve(context),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('मंजूर करा'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success),
                    ),
                  ),
                ],
              ),
            ],
            if (request.isRejected &&
                request.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('कारण: ${request.rejectionReason}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.error)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
// ADMIN: DIRECT EXPENSE ADD
// ────────────────────────────────────────────────────────
class AdminAddDirectExpenseScreen extends StatefulWidget {
  final UserModel user;
  const AdminAddDirectExpenseScreen({super.key, required this.user});
  @override
  State<AdminAddDirectExpenseScreen> createState() =>
      _AdminAddDirectExpenseScreenState();
}

class _AdminAddDirectExpenseScreenState
    extends State<AdminAddDirectExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = AppConstants.expenseCategories.first;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ExpenseService().addExpenseDirect(ExpenseModel(
        id: '',
        name: _nameController.text.trim(),
        amount: double.tryParse(_amountController.text) ?? 0,
        category: _selectedCategory,
        date: _selectedDate,
        addedByUid: widget.user.uid,
        addedByName: widget.user.name,
        createdAt: DateTime.now(),
      ));
      AppHelpers.showToast('खर्च जोडला ✓');
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      AppHelpers.showToast('चूक: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OmAppBar(title: 'थेट खर्च जोडा'),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: 'खर्चाचे नाव *',
                      prefixIcon: Icon(Icons.edit_outlined,
                          color: AppTheme.primary)),
                  validator: (v) =>
                      v!.isEmpty ? 'नाव आवश्यक आहे' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                      labelText: 'रक्कम *',
                      prefixIcon: Icon(Icons.currency_rupee,
                          color: AppTheme.primary)),
                  validator: (v) =>
                      v!.isEmpty ? 'रक्कम आवश्यक आहे' : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                      labelText: 'प्रकार *',
                      prefixIcon: Icon(Icons.category_outlined,
                          color: AppTheme.primary)),
                  items: AppConstants.expenseCategories
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedCategory = v!),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.divider),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: AppTheme.primary, size: 18),
                        const SizedBox(width: 12),
                        Text(AppHelpers.formatDate(_selectedDate)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GradientButton(
                  text: 'खर्च जोडा',
                  icon: Icons.save_outlined,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
// ADMIN: SEND NOTIFICATION
// ────────────────────────────────────────────────────────
class AdminSendNotificationScreen extends StatefulWidget {
  final UserModel user;
  const AdminSendNotificationScreen({super.key, required this.user});
  @override
  State<AdminSendNotificationScreen> createState() =>
      _AdminSendNotificationScreenState();
}

class _AdminSendNotificationScreenState
    extends State<AdminSendNotificationScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _type = 'announcement';
  bool _isLoading = false;

  final _templates = [
    'कीर्तन १० मिनिटात सुरू होईल 🙏',
    'महाप्रसादाची वेळ झाली आहे 🍚',
    'आजचे कीर्तन सुरू झाले आहे 🎵',
    'श्री हरिनाम सप्ताहात सहभागी व्हा 🙏',
    'विशेष प्रवचन सुरू होत आहे',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OmAppBar(title: 'सूचना पाठवा'),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('जलद टेम्प्लेट:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _templates.map((t) {
                  return ActionChip(
                    label: Text(t,
                        style: const TextStyle(fontSize: 12)),
                    onPressed: () {
                      _bodyController.text = t;
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'शीर्षक *',
                  prefixIcon: Icon(Icons.title, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _bodyController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'सूचना संदेश *',
                  prefixIcon: Icon(Icons.message_outlined,
                      color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'प्रकार',
                  prefixIcon:
                      Icon(Icons.category_outlined, color: AppTheme.primary),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'announcement', child: Text('घोषणा')),
                  DropdownMenuItem(
                      value: 'event', child: Text('कार्यक्रम')),
                  DropdownMenuItem(
                      value: 'mahaprasad', child: Text('महाप्रसाद')),
                ],
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 24),
              GradientButton(
                text: 'सूचना पाठवा',
                icon: Icons.send_outlined,
                onPressed: () async {
                  if (_titleController.text.isEmpty ||
                      _bodyController.text.isEmpty) {
                    AppHelpers.showToast('शीर्षक व संदेश आवश्यक आहे',
                        isError: true);
                    return;
                  }
                  setState(() => _isLoading = true);
                  try {
                    await NotificationService().saveNotification(
                        _titleController.text,
                        _bodyController.text,
                        _type);
                    AppHelpers.showToast('सूचना पाठवली ✓');
                    _titleController.clear();
                    _bodyController.clear();
                  } catch (e) {
                    AppHelpers.showToast('चूक: $e', isError: true);
                  } finally {
                    setState(() => _isLoading = false);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
// ADMIN: MAHAPRASAD SCREEN
// ────────────────────────────────────────────────────────
class AdminMahaprasadScreen extends StatefulWidget {
  final UserModel user;
  const AdminMahaprasadScreen({super.key, required this.user});
  @override
  State<AdminMahaprasadScreen> createState() =>
      _AdminMahaprasadScreenState();
}

class _AdminMahaprasadScreenState extends State<AdminMahaprasadScreen> {
  final _menuController = TextEditingController();
  File? _image;
  bool _isLoading = false;
  final _mahaprasadService = MahaprasadService();

  Future<void> _save() async {
    if (_menuController.text.isEmpty) {
      AppHelpers.showToast('मेनू माहिती आवश्यक आहे', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _mahaprasadService.setMahaprasad(
        MahaprasadModel(
          id: '',
          date: DateTime.now(),
          menuText: _menuController.text.trim(),
          updatedByUid: widget.user.uid,
          updatedByName: widget.user.name,
          createdAt: DateTime.now(),
        ),
        image: _image,
      );
      AppHelpers.showToast('महाप्रसाद अपडेट केला ✓');
    } catch (e) {
      AppHelpers.showToast('चूक: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OmAppBar(title: 'महाप्रसाद अपडेट'),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _menuController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'आजचा मेनू *',
                  hintText:
                      'जसे: भात, वरण, भाजी, पोळी, खीर...',
                  prefixIcon:
                      Icon(Icons.restaurant_menu, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final file = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 70);
                  if (file != null) {
                    setState(() => _image = File(file.path));
                  }
                },
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: _image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_image!,
                              fit: BoxFit.cover, width: double.infinity))
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 36, color: AppTheme.primary),
                            SizedBox(height: 8),
                            Text('महाप्रसाद फोटो जोडा'),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              GradientButton(
                  text: 'अपडेट करा',
                  icon: Icons.update,
                  onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
// ADMIN: SUGGESTIONS
// ────────────────────────────────────────────────────────
class AdminSuggestionsScreen extends StatelessWidget {
  final UserModel user;
  const AdminSuggestionsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OmAppBar(title: 'वापरकर्त्यांच्या सूचना'),
      body: StreamBuilder(
        stream: SuggestionService().streamAllSuggestions(),
        builder: (context, snap) {
          if (!snap.hasData || snap.data!.isEmpty) {
            return const EmptyState(
                message: 'अजून कोणत्याही सूचना नाहीत',
                icon: Icons.lightbulb_outline);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snap.data!.length,
            itemBuilder: (_, i) {
              final s = snap.data![i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        AppTheme.secondary.withOpacity(0.15),
                    child: const Icon(Icons.lightbulb,
                        color: AppTheme.secondary),
                  ),
                  title: Text(s.text),
                  subtitle: Text(
                      '${s.userName} • ${AppHelpers.formatDate(s.createdAt)}',
                      style: const TextStyle(fontSize: 11)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
// ADMIN: ISSUES
// ────────────────────────────────────────────────────────
class AdminIssuesScreen extends StatelessWidget {
  final UserModel user;
  const AdminIssuesScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OmAppBar(title: 'देणगी तक्रारी'),
      body: StreamBuilder(
        stream: IssueService().streamAllIssues(),
        builder: (context, snap) {
          if (!snap.hasData || snap.data!.isEmpty) {
            return const EmptyState(
                message: 'अजून कोणत्याही तक्रारी नाहीत',
                icon: Icons.report_problem_outlined);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snap.data!.length,
            itemBuilder: (_, i) {
              final issue = snap.data![i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(issue.donationName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold))),
                        StatusBadge(status: issue.status),
                      ]),
                      const SizedBox(height: 4),
                      Text(issue.description,
                          style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                          '${issue.userName} • ${AppHelpers.formatDate(issue.createdAt)}',
                          style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11)),
                      if (issue.status == 'open') ...[
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await IssueService().resolveIssue(
                              issueId: issue.id,
                              adminUid: user.uid,
                              adminName: user.name,
                              adminNote: 'व्यवस्थापकाने सोडवले',
                            );
                            AppHelpers.showToast('तक्रार सोडवली ✓');
                          },
                          icon: const Icon(Icons.check_circle_outline,
                              size: 16),
                          label: const Text('सोडवले म्हणून चिन्हांकित करा'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.success,
                              minimumSize: const Size.fromHeight(36)),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
