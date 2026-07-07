import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../models/expense_model.dart';
import '../../models/expense_request_model.dart';
import '../../services/expense_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_helpers.dart';
import '../../widgets/common_widgets.dart';

// ─────────────────────────────────────────────────────
// EXPENSES SCREEN (tabs: expenses list + my requests)
// ─────────────────────────────────────────────────────
class ExpensesScreen extends StatefulWidget {
  final UserModel user;
  const ExpensesScreen({super.key, required this.user});
  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final ExpenseService _expenseService;
  late final Stream<List<ExpenseModel>> _allExpensesStream;
  late final Stream<List<ExpenseRequestModel>> _myRequestsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _expenseService = ExpenseService();
    _allExpensesStream = _expenseService.streamAllExpenses();
    _myRequestsStream =
        _expenseService.streamUserExpenseRequests(widget.user.uid);
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
        title: const Text('खर्च'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'एकूण खर्च'),
            Tab(text: 'माझ्या विनंत्या'),
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
          _ExpenseListTab(
            user: widget.user,
            expensesStream: _allExpensesStream,
          ),
          _MyRequestsTab(
            user: widget.user,
            requestsStream: _myRequestsStream,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    SubmitExpenseRequestScreen(user: widget.user))),
        icon: const Icon(Icons.add),
        label: const Text('खर्च विनंती'),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// EXPENSE LIST TAB
// ─────────────────────────────────────────────────────
class _ExpenseListTab extends StatelessWidget {
  final UserModel user;
  final Stream<List<ExpenseModel>> expensesStream;

  const _ExpenseListTab({
    required this.user,
    required this.expensesStream,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ExpenseModel>>(
      stream: expensesStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary));
        }
        if (!snap.hasData || snap.data!.isEmpty) {
          return const EmptyState(
              message: 'अजून कोणताही खर्च नाही',
              icon: Icons.receipt_long_outlined);
        }

        final expenses = snap.data!;
        final total = expenses.fold<double>(0, (s, e) => s + e.amount);

        return Column(
          children: [
            Container(
              margin: const EdgeInsets.all(12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.error, Color(0xFFB71C1C)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('${expenses.length} खर्च नोंदी',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                  const Spacer(),
                  Text(AppHelpers.formatCurrency(total),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: expenses.length,
                itemBuilder: (_, i) => _ExpenseCard(
                    expense: expenses[i], isAdmin: user.isAdmin),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final bool isAdmin;

  const _ExpenseCard({required this.expense, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              AppHelpers.getCategoryIcon(expense.category),
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: Text(expense.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${expense.category} • ${AppHelpers.formatDate(expense.date)}',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AmountText(
                amount: expense.amount,
                fontSize: 15,
                color: AppTheme.error),
            if (expense.requestId != null)
              const Text('विनंतीनुसार',
                  style: TextStyle(
                      fontSize: 10, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// MY REQUESTS TAB
// ─────────────────────────────────────────────────────
class _MyRequestsTab extends StatelessWidget {
  final UserModel user;
  final Stream<List<ExpenseRequestModel>> requestsStream;

  const _MyRequestsTab({
    required this.user,
    required this.requestsStream,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ExpenseRequestModel>>(
      stream: requestsStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary));
        }
        if (!snap.hasData || snap.data!.isEmpty) {
          return EmptyState(
            message: 'अजून कोणतीही विनंती नाही',
            icon: Icons.inbox_outlined,
            action: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          SubmitExpenseRequestScreen(user: user))),
              icon: const Icon(Icons.add),
              label: const Text('विनंती करा'),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: snap.data!.length,
          itemBuilder: (_, i) =>
              _RequestCard(request: snap.data![i]),
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  final ExpenseRequestModel request;
  const _RequestCard({required this.request});

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
                Expanded(
                  child: Text(request.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                StatusBadge(status: request.status),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                AmountText(
                    amount: request.amount,
                    fontSize: 16,
                    color: AppTheme.error),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(request.category,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.primary)),
                ),
              ],
            ),
            if (request.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(request.description,
                  style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 6),
            Text(AppHelpers.formatDateTime(request.timestamp),
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11)),
            if (request.isRejected && request.rejectionReason != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 14, color: AppTheme.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('कारण: ${request.rejectionReason}',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.error)),
                    ),
                  ],
                ),
              ),
            ],
            if (request.isApproved) ...[
              const SizedBox(height: 6),
              Text(
                  'मंजूर: ${request.approvedByName ?? ''} • ${AppHelpers.formatDate(request.resolvedAt ?? DateTime.now())}',
                  style: const TextStyle(
                      color: AppTheme.success, fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// SUBMIT EXPENSE REQUEST SCREEN
// ─────────────────────────────────────────────────────
class SubmitExpenseRequestScreen extends StatefulWidget {
  final UserModel user;
  const SubmitExpenseRequestScreen({super.key, required this.user});

  @override
  State<SubmitExpenseRequestScreen> createState() =>
      _SubmitExpenseRequestScreenState();
}

class _SubmitExpenseRequestScreenState
    extends State<SubmitExpenseRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _expenseService = ExpenseService();

  String _selectedCategory = AppConstants.expenseCategories.first;
  File? _image;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file != null) setState(() => _image = File(file.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final request = ExpenseRequestModel(
        id: '',
        userId: widget.user.uid,
        userName: widget.user.name,
        name: _nameController.text.trim(),
        amount: double.tryParse(_amountController.text) ?? 0,
        category: _selectedCategory,
        description: _descController.text.trim(),
        status: AppConstants.statusPending,
        timestamp: DateTime.now(),
      );

      await _expenseService.submitExpenseRequest(request, image: _image);
      AppHelpers.showToast('विनंती पाठवली ✓');
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
      appBar: const OmAppBar(title: 'खर्च विनंती'),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.warning.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppTheme.warning, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'आपली विनंती व्यवस्थापकांकडे मंजुरीसाठी जाईल',
                          style: TextStyle(
                              color: AppTheme.warning, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'खर्चाचे नाव *',
                    prefixIcon:
                        Icon(Icons.edit_outlined, color: AppTheme.primary),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'नाव आवश्यक आहे' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'रक्कम (₹) *',
                    prefixIcon:
                        Icon(Icons.currency_rupee, color: AppTheme.primary),
                  ),
                  validator: (v) {
                    if (v!.isEmpty) return 'रक्कम आवश्यक आहे';
                    if (double.tryParse(v) == null ||
                        double.parse(v) <= 0) {
                      return 'योग्य रक्कम टाका';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'खर्च प्रकार *',
                    prefixIcon:
                        Icon(Icons.category_outlined, color: AppTheme.primary),
                  ),
                  items: AppConstants.expenseCategories
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedCategory = v!),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'वर्णन *',
                    prefixIcon: Icon(Icons.description_outlined,
                        color: AppTheme.primary),
                    hintText: 'खर्चाचे तपशीलवार वर्णन द्या',
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'वर्णन आवश्यक आहे' : null,
                ),
                const SizedBox(height: 20),
                const Text('फोटो पुरावा (ऐच्छिक)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 110,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.04),
                      border: Border.all(
                          color: AppTheme.primary.withOpacity(0.25)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_image!,
                                fit: BoxFit.cover,
                                width: double.infinity))
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined,
                                  color: AppTheme.primary, size: 28),
                              SizedBox(height: 6),
                              Text('फोटो जोडा',
                                  style: TextStyle(
                                      color: AppTheme.primary)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                GradientButton(
                  text: 'विनंती पाठवा',
                  icon: Icons.send_outlined,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
