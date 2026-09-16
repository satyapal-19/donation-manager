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
import '../../widgets/upi_qr_dialog.dart';

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
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _itemDescController = TextEditingController();
  final _utrController = TextEditingController();
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
      _phoneController.text = d.donorPhone ?? '';
      _amountController.text = d.amount.toStringAsFixed(0);
      _itemDescController.text = d.itemDescription ?? '';
      _utrController.text = d.utrNumber ?? '';
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
    _phoneController.dispose();
    _amountController.dispose();
    _itemDescController.dispose();
    _utrController.dispose();
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
      final utr = _selectedType == 'ऑनलाइन' ? _utrController.text.trim() : null;
      final isNewOrChangedUtr = widget.existingDonation == null ||
          widget.existingDonation!.utrNumber != utr;

      if (utr != null && utr.isNotEmpty && isNewOrChangedUtr) {
        final alreadyUsed = await _donationService.isUtrAlreadyUsed(utr);
        if (alreadyUsed) {
          AppHelpers.showToast('हा UTR क्रमांक आधीच नोंदवला गेला आहे! कृपया योग्य UTR टाका.', isError: true);
          setState(() => _isLoading = false);
          return;
        }
      }

      final paymentStatus = _selectedType == 'ऑनलाइन'
          ? (widget.existingDonation?.paymentStatus ??
              (widget.user.isAdmin ? AppConstants.paymentStatusVerified : AppConstants.paymentStatusPending))
          : AppConstants.paymentStatusVerified;

      final donation = DonationModel(
        id: widget.existingDonation?.id ?? '',
        donorName: _nameController.text.trim(),
        village: _villageController.text.trim().isEmpty
            ? _defaultVillage
            : _villageController.text.trim(),
        donorPhone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        amount: double.tryParse(_amountController.text) ?? 0,
        type: _selectedType,
        purpose: _selectedPurpose,
        proofImageUrl: widget.existingDonation?.proofImageUrl,
        addedByUid: widget.user.uid,
        addedByName: widget.user.name,
        createdAt: widget.existingDonation?.createdAt ?? DateTime.now(),
        itemDescription:
            _selectedType == 'वस्तू' ? _itemDescController.text.trim() : null,
        utrNumber: utr,
        paymentStatus: paymentStatus,
        verifiedByUid: widget.user.isAdmin ? widget.user.uid : widget.existingDonation?.verifiedByUid,
        verifiedByName: widget.user.isAdmin ? widget.user.name : widget.existingDonation?.verifiedByName,
        verifiedAt: widget.user.isAdmin ? DateTime.now() : widget.existingDonation?.verifiedAt,
      );

      if (widget.existingDonation != null) {
        await _donationService.updateDonation(donation,
            newProofImage: _proofImage);
        AppHelpers.showToast('देणगी अपडेट केली');
      } else {
        await _donationService.addDonation(donation, proofImage: _proofImage);
        AppHelpers.showToast(
          paymentStatus == AppConstants.paymentStatusPending
              ? 'देणगी जोडली! (पडताळणी प्रलंबित) ✓'
              : 'देणगी जोडली ✓',
        );
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
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'मोबाईल नंबर (ऐच्छिक - WhatsApp पावतीसाठी)',
                    hintText: '9876543210',
                    prefixIcon:
                        Icon(Icons.phone_outlined, color: AppTheme.primary),
                    prefixText: '+91 ',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (v) {
                    if (v != null && v.isNotEmpty && v.length != 10) {
                      return 'कृपया वैध १० अंकी मोबाईल नंबर टाका';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.05),
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
                                : AppTheme.primary.withValues(alpha: 0.05),
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

                if (_selectedType == 'ऑनलाइन') ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.qr_code_2, color: Colors.blue, size: 22),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'थेट UPI पेमेंट (0% शुल्क)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => UpiQrDialog.show(
                                context,
                                user: widget.user,
                                initialAmount: double.tryParse(_amountController.text),
                              ),
                              child: const Text('QR / ॲप उघडा'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _utrController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(12),
                          ],
                          decoration: const InputDecoration(
                            labelText: '१२-अंकी UPI UTR / Ref No. *',
                            hintText: 'उदा. 425109876543',
                            helperText: 'GPay/PhonePe मधील १२ अंकी बँक संदर्भ क्रमांक',
                            prefixIcon: Icon(Icons.verified_outlined, color: Colors.blue),
                          ),
                          validator: (v) {
                            if (_selectedType == 'ऑनलाइन') {
                              if (v == null || v.trim().isEmpty) {
                                return '१२-अंकी UTR क्रमांक आवश्यक आहे';
                              }
                              if (!RegExp(r'^\d{12}$').hasMatch(v.trim())) {
                                return 'UTR बरोबर १२ अंकांचा असावा';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],

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
                                : AppTheme.secondary.withValues(alpha: 0.05),
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
                      color: AppTheme.primary.withValues(alpha: 0.04),
                      border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.25)),
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
