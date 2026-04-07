import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/expense_model.dart';
import '../models/expense_request_model.dart';
import '../utils/app_constants.dart';

class ExpenseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<List<ExpenseModel>> streamAllExpenses() {
    return _db
        .collection(AppConstants.expensesCollection)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ExpenseModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<ExpenseRequestModel>> streamPendingExpenseRequests() {
    return _db
        .collection(AppConstants.expenseRequestsCollection)
        .where('status', isEqualTo: AppConstants.statusPending)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ExpenseRequestModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<ExpenseRequestModel>> streamAllExpenseRequests() {
    return _db
        .collection(AppConstants.expenseRequestsCollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ExpenseRequestModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<ExpenseRequestModel>> streamUserExpenseRequests(
    String userId,
  ) {
    return _db
        .collection(AppConstants.expenseRequestsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ExpenseRequestModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> submitExpenseRequest(
    ExpenseRequestModel request, {
    File? image,
  }) async {
    final docRef = _db.collection(AppConstants.expenseRequestsCollection).doc();
    final requestId = docRef.id;

    String? imageUrl = request.imageUrl;
    if (image != null) {
      final fileName = image.path.split(Platform.pathSeparator).last;
      final ref = _storage.ref().child(
        '${AppConstants.expenseRequestsCollection}/$requestId\_$fileName',
      );
      await ref.putFile(image);
      imageUrl = await ref.getDownloadURL();
    }

    final finalRequest = ExpenseRequestModel(
      id: requestId,
      userId: request.userId,
      userName: request.userName,
      name: request.name,
      amount: request.amount,
      category: request.category,
      description: request.description,
      status: request.status,
      timestamp: request.timestamp,
      imageUrl: imageUrl,
      approvedByName: request.approvedByName,
      resolvedAt: request.resolvedAt,
      rejectionReason: request.rejectionReason,
    );

    await docRef.set(finalRequest.toMap());
  }

  Future<void> addExpenseDirect(ExpenseModel expense) async {
    // Admin can add direct expenses (no requestId).
    final docRef = _db.collection(AppConstants.expensesCollection).doc();
    final expenseId = docRef.id;
    final finalExpense = ExpenseModel(
      id: expenseId,
      name: expense.name,
      amount: expense.amount,
      category: expense.category,
      date: expense.date,
      requestId: expense.requestId,
      addedByUid: expense.addedByUid,
      addedByName: expense.addedByName,
      createdAt: expense.createdAt,
    );

    await docRef.set(finalExpense.toMap());
  }

  Future<void> approveExpenseRequest({
    required String requestId,
    required String adminUid,
    required String adminName,
  }) async {
    final reqRef =
        _db.collection(AppConstants.expenseRequestsCollection).doc(requestId);
    final expenseCollection = _db.collection(AppConstants.expensesCollection);

    await _db.runTransaction((tx) async {
      final reqSnap = await tx.get(reqRef);
      if (!reqSnap.exists) {
        throw StateError('Expense request not found: $requestId');
      }

      final data = reqSnap.data() as Map<String, dynamic>;
      final currentStatus = (data['status'] ?? '') as String;
      if (currentStatus != AppConstants.statusPending) {
        throw StateError('Request is already processed');
      }

      final timestamp = Timestamp.now();
      final now = DateTime.now();

      // Update request status.
      tx.update(reqRef, {
        'status': AppConstants.statusApproved,
        'approvedByName': adminName,
        'resolvedAt': timestamp,
      });

      // Create expense entry.
      final expenseRef = expenseCollection.doc();
      final expense = ExpenseModel(
        id: expenseRef.id,
        name: (data['name'] ?? '') as String,
        amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
        category: (data['category'] ?? '') as String,
        date: now,
        requestId: requestId,
        addedByUid: adminUid,
        addedByName: adminName,
        createdAt: now,
      );

      tx.set(expenseRef, expense.toMap());
    });
  }

  Future<void> rejectExpenseRequest({
    required String requestId,
    required String adminUid,
    required String adminName,
    String? reason,
  }) async {
    final reqRef =
        _db.collection(AppConstants.expenseRequestsCollection).doc(requestId);

    await _db.runTransaction((tx) async {
      final reqSnap = await tx.get(reqRef);
      if (!reqSnap.exists) {
        throw StateError('Expense request not found: $requestId');
      }

      final data = reqSnap.data() as Map<String, dynamic>;
      final currentStatus = (data['status'] ?? '') as String;
      if (currentStatus != AppConstants.statusPending) {
        throw StateError('Request is already processed');
      }

      tx.update(reqRef, {
        'status': AppConstants.statusRejected,
        'rejectionReason': reason,
        'resolvedAt': Timestamp.now(),
        'approvedByName': adminName, // kept for UI consistency if used later
      });
    });
  }
}

