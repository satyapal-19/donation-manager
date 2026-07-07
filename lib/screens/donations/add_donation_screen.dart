import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/donation_model.dart';
import '../../models/user_model.dart';
import '../../services/donation_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_helpers.dart';
import '../../widgets/common_widgets.dart';

class AddDonationScreen extends StatefulWidget {
  final UserModel user;
  final DonationModel? existingDonation;

  const AddDonationScreen({super.key, required this.user, this.existingDonation});

  @override
  State<AddDonationScreen> createState() => _AddDonationScreenState();
}

class _AddDonationScreenState extends State<AddDonationScreen> {
  static const String _defaultVillage = 'चिंचोली-भोसे';
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _villageController = TextEditingController();
  final _amountController = TextEditingController();
  final _itemDescController = TextEditingController();
  final _donationService = DonationService();

  String _selectedType = 'रोख';
  String _selectedPurpose = 'सामान्य';
  File? _proofImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingDonation != null) {
      final d = widget.existingDonation!;
      _nameController.text = d.donorName;
      _villageController.text = d.village;
      _amountController.text = d.amount.toStringAsFixed(0);
      _itemDescController.text = d.itemDescription ?? '';
      _selectedType = d.type;
      _selectedPurpose = d.purpose;
    } else {
      _villageController.text = _defaultVillage;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _villageController.dispose();
    _amountController.dispose();
    _itemDescController.dispose();
    super.dispose();
  }

  Future<void> _pickProof() async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file != null) setState(() => _proofImage = File(file.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final donation = DonationModel(
        id: widget.existingDonation?.id ?? '',
        donorName: _nameController.text.trim(),
        village: _villageController.text.trim().isEmpty
            ? _defaultVillage
            : _villageController.text.trim(),
        amount: double.tryParse(_amountController.text) ?? 0,
        type: _selectedType,
        purpose: _selectedPurpose,
        proofImageUrl: widget.existingDonation?.proofImageUrl,
        addedByUid: widget.user.uid,
        addedByName: widget.user.name,
        createdAt: widget.existingDonation?.createdAt ?? DateTime.now(),
        itemDescription:
            _selectedType == 'वस्तू' ? _itemDescController.text.trim() : null,
      );

      if (widget.existingDonation != null) {
        await _donationService.updateDonation(donation,
            newProofImage: _proofImage);
        AppHelpers.showToast('देणगी अपडेट केली');
      } else {
        await _donationService.addDonation(donation, proofImage: _proofImage);
        AppHelpers.showToast('देणगी जोडली ✓');
      }

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
      appBar: OmAppBar(
        title: widget.existingDonation != null ? 'देणगी बदला' : 'देणगी जोडा',
      ),
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
                    labelText: 'देणगीदार नाव *',
                    prefixIcon:
                        Icon(Icons.person_outline, color: AppTheme.primary),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      v!.isEmpty ? 'नाव आवश्यक आहे' : null,
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: AppTheme.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'गाव: चिंचोली-भोसे (डीफॉल्ट)',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'रक्कम (₹) *',
                    prefixIcon: Icon(Icons.currency_rupee,
                        color: AppTheme.primary),
                  ),
                  validator: (v) {
                    if (v!.isEmpty) return 'रक्कम आवश्यक आहे';
                    if (double.tryParse(v) == null || double.parse(v) <= 0) {
                      return 'योग्य रक्कम टाका';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Type selection
                const Text('प्रकार *',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: AppConstants.donationTypes.map((type) {
                    final selected = _selectedType == type;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = type),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? AppTheme.primary
                                  : AppTheme.divider,
                            ),
                          ),
                          child: Text(
                            type,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color:
                                  selected ? Colors.white : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                if (_selectedType == 'वस्तू') ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _itemDescController,
                    decoration: const InputDecoration(
                      labelText: 'वस्तूचे वर्णन *',
                      prefixIcon: Icon(Icons.inventory_outlined,
                          color: AppTheme.primary),
                      hintText: 'जसे: भांडी, पाणी, इ.',
                    ),
                    validator: (v) => _selectedType == 'वस्तू' && v!.isEmpty
                        ? 'वर्णन आवश्यक आहे'
                        : null,
                  ),
                ],

                const SizedBox(height: 14),

                // Purpose
                const Text('उद्देश *',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: AppConstants.donationPurposes.map((p) {
                    final selected = _selectedPurpose == p;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPurpose = p),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.secondary
                                : AppTheme.secondary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? AppTheme.secondary
                                  : AppTheme.divider,
                            ),
                          ),
                          child: Text(
                            p,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Proof image
                const Text('पुरावा फोटो (ऐच्छिक)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickProof,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.04),
                      border: Border.all(
                          color: AppTheme.primary.withOpacity(0.25)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _proofImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_proofImage!,
                                fit: BoxFit.cover, width: double.infinity))
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.upload_file_outlined,
                                  color: AppTheme.primary, size: 28),
                              SizedBox(height: 6),
                              Text('फोटो अपलोड करा',
                                  style: TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 13)),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 24),
                GradientButton(
                  text: widget.existingDonation != null
                      ? 'बदल जतन करा'
                      : 'देणगी जोडा',
                  icon: Icons.volunteer_activism,
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
