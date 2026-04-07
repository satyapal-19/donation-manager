import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/issue_model.dart';
import '../models/mahaprasad_model.dart';
import '../models/suggestion_model.dart';
import '../utils/app_constants.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // For a minimal working app: keep this handler empty.
  // You can extend it later to show local notifications.
}

class NotificationService {
  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    try {
      // Request permission (iOS) - safe on Android too.
      await FirebaseMessaging.instance.requestPermission();
      await FirebaseMessaging.instance.getToken();
    } catch (e) {
      // Keep app booting even when Firebase messaging is not configured yet.
      print('Notification init skipped: $e');
    }
  }

  Future<void> subscribeAdmin() async {
    // Admins should listen on this topic.
    await FirebaseMessaging.instance.subscribeToTopic('admin');
  }

  Future<void> saveNotification(String title, String body, String type) async {
    await FirebaseFirestore.instance
        .collection(AppConstants.notificationsCollection)
        .add({
      'title': title,
      'body': body,
      'type': type,
      'createdAt': Timestamp.now(),
    });
  }
}

class MahaprasadService {
  String _todayDocId() {
    final now = DateTime.now();
    final yyyy = now.year.toString().padLeft(4, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  String _docIdFromDate(DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  Stream<MahaprasadModel?> streamTodayMahaprasad() {
    final docId = _todayDocId();
    return FirebaseFirestore.instance
        .collection(AppConstants.mahaprasadCollection)
        .doc(docId)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return null;
      return MahaprasadModel.fromMap(snap.data() as Map<String, dynamic>, snap.id);
    });
  }

  Future<void> setMahaprasad(
    MahaprasadModel model, {
    File? image,
  }) async {
    final docId = _docIdFromDate(model.date);

    String? imageUrl = model.imageUrl;
    if (image != null) {
      final fileName = image.path.split(Platform.pathSeparator).last;
      final ref = FirebaseStorage.instance
          .ref()
          .child('${AppConstants.mahaprasadCollection}/$docId\_$fileName');
      await ref.putFile(image);
      imageUrl = await ref.getDownloadURL();
    }

    await FirebaseFirestore.instance
        .collection(AppConstants.mahaprasadCollection)
        .doc(docId)
        .set({
      'date': Timestamp.fromDate(model.date),
      'menuText': model.menuText,
      'imageUrl': imageUrl,
      'updatedByUid': model.updatedByUid,
      'updatedByName': model.updatedByName,
      'createdAt': Timestamp.fromDate(model.createdAt),
    });
  }
}

class SuggestionService {
  Future<void> submitSuggestion(SuggestionModel model) async {
    await FirebaseFirestore.instance
        .collection(AppConstants.suggestionsCollection)
        .add({
      'userId': model.userId,
      'userName': model.userName,
      'text': model.text,
      'createdAt': Timestamp.fromDate(model.createdAt),
    });
  }

  Stream<List<SuggestionModel>> streamAllSuggestions() {
    return FirebaseFirestore.instance
        .collection(AppConstants.suggestionsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SuggestionModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<SuggestionModel>> streamUserSuggestions(String userId) {
    return FirebaseFirestore.instance
        .collection(AppConstants.suggestionsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SuggestionModel.fromMap(d.data(), d.id))
            .toList());
  }
}

class IssueService {
  Stream<List<IssueModel>> streamAllIssues() {
    return FirebaseFirestore.instance
        .collection(AppConstants.issuesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => IssueModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> resolveIssue({
    required String issueId,
    required String adminUid,
    required String adminName,
    required String adminNote,
  }) async {
    await FirebaseFirestore.instance
        .collection(AppConstants.issuesCollection)
        .doc(issueId)
        .update({
      'status': 'resolved',
      'resolvedAt': Timestamp.now(),
      'resolvedByUid': adminUid,
      'resolvedByName': adminName,
      'adminNote': adminNote,
    });
  }
}

