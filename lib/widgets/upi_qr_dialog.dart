import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr/qr.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/donation_model.dart';
import '../models/user_model.dart';
import '../services/donation_service.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_constants.dart';
import '../utils/app_helpers.dart';

class UpiQrDialog extends StatefulWidget {
  final String upiId;
  final String payeeName;
  final double? initialAmount;
  final UserModel? user;
  final DonationService? donationService;

  const UpiQrDialog({
    super.key,
    this.upiId = AppConstants.defaultUpiId,
    this.payeeName = AppConstants.defaultPayeeName,
    this.initialAmount,
    this.user,
    this.donationService,
  });

  static Future<void> show(
    BuildContext context, {
    String upiId = AppConstants.defaultUpiId,
    String payeeName = AppConstants.defaultPayeeName,
    double? initialAmount,
    UserModel? user,
    DonationService? donationService,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpiQrDialog(
        upiId: upiId,
        payeeName: payeeName,
        initialAmount: initialAmount,
        user: user,
        donationService: donationService,
      ),
    );
  }

  @override
  State<UpiQrDialog> createState() => _UpiQrDialogState();
}

class _UpiQrDialogState extends State<UpiQrDialog> {
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  final _villageController = TextEditingController(text: 'चिंचोली-भोसे');
  final _phoneController = TextEditingController();
  final _utrController = TextEditingController();
  DonationService get _donationService =>
      widget.donationService ?? DonationService();

  final List<int> _presetAmounts = [101, 251, 501, 1001, 2100, 5001];
  int? _selectedPreset;
  bool _showUtrForm = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      _amountController.text = widget.initialAmount!.toStringAsFixed(0);
      final intVal = widget.initialAmount!.toInt();
      if (_presetAmounts.contains(intVal)) {
        _selectedPreset = intVal;
      }
    } else {
      _selectedPreset = 501;
      _amountController.text = '501';
    }

    if (widget.user != null && !widget.user!.isAdmin) {
      _nameController.text = widget.user!.name;
      if (widget.user!.mobile.isNotEmpty) {
        _phoneController.text = widget.user!.mobile;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _villageController.dispose();
    _phoneController.dispose();
    _utrController.dispose();
    super.dispose();
  }

  String _buildUpiUri() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final amtParam = amount > 0 ? '&am=${amount.toStringAsFixed(2)}' : '';
    final encodedPn = Uri.encodeComponent(widget.payeeName);
    final donorRef = _phoneController.text.trim().isNotEmpty
        ? _phoneController.text.trim()
        : 'Devotee';
    final tn = Uri.encodeComponent('Saptah Donation $donorRef');
    return 'upi://pay?pa=${widget.upiId}&pn=$encodedPn$amtParam&cu=INR&tn=$tn';
  }

  Future<void> _launchUpiIntent() async {
    final upiUriString = _buildUpiUri();
    final uri = Uri.parse(upiUriString);

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        AppHelpers.showToast('UPI ॲप थेट उघडता आले नाही. कृपया खालील QR कोड स्कॅन करा.');
      } else {
        setState(() {
          _showUtrForm = true;
        });
      }
    } catch (_) {
      AppHelpers.showToast('UPI ॲप उघडता आले नाही. कृपया QR कोड स्कॅन करा.');
    }
  }

  Future<void> _submitDonationWithUtr() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      AppHelpers.showToast('कृपया योग्य देणगी रक्कम टाका', isError: true);
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppHelpers.showToast('कृपया देणगीदाराचे नाव टाका', isError: true);
      return;
    }

    final utr = _utrController.text.trim();
    if (utr.isEmpty) {
      AppHelpers.showToast('कृपया १२-अंकी UPI UTR / संदर्भ क्रमांक टाका', isError: true);
      return;
    }

    if (!RegExp(r'^\d{12}$').hasMatch(utr)) {
      AppHelpers.showToast('UTR क्रमांक बरोबर १२ अंकांचा असावा (फक्त अंक)', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final alreadyUsed = await _donationService.isUtrAlreadyUsed(utr);
      if (alreadyUsed) {
        AppHelpers.showToast('हा UTR क्रमांक आधीच नोंदवला गेला आहे! कृपया योग्य UTR टाका.', isError: true);
        setState(() => _isSubmitting = false);
        return;
      }

      final village = _villageController.text.trim().isEmpty
          ? 'चिंचोली-भोसे'
          : _villageController.text.trim();
      final phone = _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim();

      final currentUid = widget.user?.uid ?? 'online_donor';
      final currentUserName = widget.user?.name ?? name;
      final isAdmin = widget.user?.isAdmin ?? false;

      final donation = DonationModel(
        id: '',
        donorName: name,
        village: village,
        amount: amount,
        type: 'ऑनलाइन',
        purpose: 'सामान्य',
        proofImageUrl: null,
        addedByUid: currentUid,
        addedByName: currentUserName,
        createdAt: DateTime.now(),
        itemDescription: null,
        donorPhone: phone,
        utrNumber: utr,
        paymentStatus: isAdmin ? AppConstants.paymentStatusVerified : AppConstants.paymentStatusPending,
        verifiedByUid: isAdmin ? currentUid : null,
        verifiedByName: isAdmin ? currentUserName : null,
        verifiedAt: isAdmin ? DateTime.now() : null,
      );

      await _donationService.addDonation(donation);

      if (!mounted) return;
      Navigator.pop(context);

      AppHelpers.showToast(
        isAdmin
            ? 'ऑनलाइन देणगी यशस्वीपणे नोंदवली व स्वीकृत केली ✓'
            : 'देणगी नोंदवली! समिती पडताळणीनंतर पावती अंतिम होईल ✓',
      );

      // Offer to share receipt
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('🚩 देणगी नोंद पूर्ण'),
          content: Text(
            'देणगीदार: $name\nरक्कम: ₹${amount.toStringAsFixed(0)}\nUTR: $utr\n\nपावती आता WhatsApp वर शेअर करायची आहे का?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('बंद करा'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
              icon: const Icon(Icons.share, color: Colors.white, size: 18),
              label: const Text('WhatsApp पावती', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.pop(ctx);
                ExportService().shareDonationReceiptText(donation);
              },
            ),
          ],
        ),
      );
    } catch (e) {
      AppHelpers.showToast('चूक: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final upiUri = _buildUpiUri();

    QrImage? qrImage;
    try {
      final qrCode = QrCode.fromData(
        data: upiUri,
        errorCorrectLevel: QrErrorCorrectLevel.M,
      );
      qrImage = QrImage(qrCode);
    } catch (_) {
      qrImage = null;
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        mediaQuery.viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.9,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.qr_code_2_rounded,
                    color: AppTheme.primary, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'UPI QR कोडद्वारे देणगी',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary),
                      ),
                      Text(
                        widget.payeeName,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 20),

            // Quick preset chips
            const Text(
              'रक्कम निवडा (₹)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _presetAmounts.map((amt) {
                final isSelected = _selectedPreset == amt;
                return ChoiceChip(
                  label: Text('₹$amt'),
                  selected: isSelected,
                  selectedColor: AppTheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedPreset = amt;
                        _amountController.text = amt.toString();
                      } else {
                        _selectedPreset = null;
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (val) {
                final parsed = int.tryParse(val);
                setState(() {
                  _selectedPreset =
                      parsed != null && _presetAmounts.contains(parsed)
                          ? parsed
                          : null;
                });
              },
              decoration: InputDecoration(
                labelText: 'रक्कम टाका (₹) *',
                prefixIcon:
                    const Icon(Icons.currency_rupee, color: AppTheme.primary),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _amountController.clear();
                    setState(() => _selectedPreset = null);
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Direct Intent Button (One tap launch UPI app)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.open_in_new, size: 20),
              label: const Text(
                'पेमेंट ॲप उघडा (GPay / PhonePe / Paytm)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              onPressed: _launchUpiIntent,
            ),
            const SizedBox(height: 16),

            // QR Display Card
            Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (qrImage != null)
                      CustomPaint(
                        size: const Size(180, 180),
                        painter: _QrCanvasPainter(qrImage: qrImage),
                      )
                    else
                      const SizedBox(
                        height: 180,
                        width: 180,
                        child: Center(
                            child: Text('QR तयार करण्यात अडचण आली')),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.security,
                            size: 14, color: AppTheme.success),
                        const SizedBox(width: 4),
                        Text(
                          'स्कॅन करून भरा: कोणत्याही UPI ॲपद्वारे',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // UPI ID copy box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined,
                      size: 20, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('समितीचा अधिकृत UPI ID',
                            style:
                                TextStyle(fontSize: 10, color: Colors.grey)),
                        Text(
                          widget.upiId,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.upiId));
                      AppHelpers.showToast('UPI ID कॉपी केली ✓');
                    },
                    icon: const Icon(Icons.copy, size: 15),
                    label: const Text('कॉपी'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Toggle / UTR Confirmation Section
            InkWell(
              onTap: () => setState(() => _showUtrForm = !_showUtrForm),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: AppTheme.secondary, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'पेमेंट केले असल्यास पावतीसाठी UTR नोंदवा',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      _showUtrForm ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: AppTheme.secondary,
                    ),
                  ],
                ),
              ),
            ),

            if (_showUtrForm) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'देणगीदार नाव *',
                  prefixIcon: Icon(Icons.person_outline, color: AppTheme.primary),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _villageController,
                      decoration: const InputDecoration(
                        labelText: 'गाव',
                        prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'मोबाईल नंबर',
                        prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.primary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
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
                  prefixIcon: Icon(Icons.verified_outlined, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isSubmitting ? null : _submitDonationWithUtr,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline, size: 20),
                label: Text(
                  _isSubmitting ? 'तपासत आहे...' : 'देणगी व पावती नोंदवा',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QrCanvasPainter extends CustomPainter {
  final QrImage qrImage;

  const _QrCanvasPainter({
    required this.qrImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..style = PaintingStyle.fill;

    final moduleCount = qrImage.moduleCount;
    final pixelSize = size.width / moduleCount;

    for (var x = 0; x < moduleCount; x++) {
      for (var y = 0; y < moduleCount; y++) {
        if (qrImage.isDark(y, x)) {
          canvas.drawRect(
            Rect.fromLTWH(x * pixelSize, y * pixelSize, pixelSize, pixelSize),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrCanvasPainter oldDelegate) =>
      oldDelegate.qrImage != qrImage;
}
