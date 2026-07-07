import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_constants.dart';

class AppHelpers {
  // Used by showToast (no context passed in many of your screens).
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static const _monthsEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String formatCurrency(double amount) {
    final formatted = NumberFormat('#,##0.##', 'en_IN').format(amount);
    return '₹$formatted';
  }

  /// No `initializeDateFormatting` required (avoids "Locale data has not been initialized" in profile/tests).
  static String formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = _monthsEn[date.month - 1];
    return '$d $m ${date.year}';
  }

  static String formatDateTime(DateTime dateTime) {
    final d = dateTime.day.toString().padLeft(2, '0');
    final m = _monthsEn[dateTime.month - 1];
    final h24 = dateTime.hour;
    final h12 = h24 == 0
        ? 12
        : (h24 > 12 ? h24 - 12 : h24);
    final mm = dateTime.minute.toString().padLeft(2, '0');
    final ap = h24 >= 12 ? 'PM' : 'AM';
    return '$d $m ${dateTime.year} • ${h12.toString().padLeft(2, '0')}:$mm $ap';
  }

  static String getStatusText(String status) {
    switch (status) {
      case AppConstants.statusPending:
        return 'प्रलंबित';
      case AppConstants.statusApproved:
        return 'मंजूर';
      case AppConstants.statusRejected:
        return 'नाकारलेले';
      default:
        return status;
    }
  }

  static String getCategoryIcon(String category) {
    final c = category.trim();
    switch (c) {
      case 'अन्नदान':
        return '🍲';
      case 'प्रवास':
        return '🧳';
      case 'साधने':
        return '🛠️';
      case 'इतर':
        return '🧾';
      default:
        return '🧾';
    }
  }

  static Future<void> showToast(
    String message, {
    bool isError = false,
  }) async {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'ठीक',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('रद्द करा'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: isDestructive ? Colors.red : null,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}

