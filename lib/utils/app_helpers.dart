import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_constants.dart';

class AppHelpers {
  // Used by showToast (no context passed in many of your screens).
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static String formatCurrency(double amount) {
    final formatted = NumberFormat('#,##0.##', 'en_IN').format(amount);
    return '₹$formatted';
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy', 'en_IN').format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy • hh:mm a', 'en_IN').format(dateTime);
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

