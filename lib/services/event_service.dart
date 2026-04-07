import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/event_model.dart';
import '../utils/app_constants.dart';

class EventService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<List<EventModel>> streamEventsByDay(int dayNumber) {
    return _db
        .collection(AppConstants.eventsCollection)
        .where('dayNumber', isEqualTo: dayNumber)
        .orderBy('time')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => EventModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> addEvent(
    EventModel event, {
    File? maharajPhoto,
  }) async {
    final docRef = _db.collection(AppConstants.eventsCollection).doc();
    final eventId = docRef.id;

    String? maharajPhotoUrl = event.maharajPhotoUrl;
    if (maharajPhoto != null) {
      final fileName = maharajPhoto.path.split(Platform.pathSeparator).last;
      final ref = _storage
          .ref()
          .child('maharaj_photos/${eventId}_$fileName');
      await ref.putFile(maharajPhoto);
      maharajPhotoUrl = await ref.getDownloadURL();
    }

    final finalEvent = EventModel(
      id: eventId,
      dayNumber: event.dayNumber,
      time: event.time,
      title: event.title,
      maharajName: event.maharajName,
      maharajLocation: event.maharajLocation,
      maharajPhotoUrl: maharajPhotoUrl,
      description: event.description,
      createdAt: event.createdAt,
    );

    await docRef.set(finalEvent.toMap());
  }

  Future<void> updateEvent(
    EventModel event, {
    File? newMaharajPhoto,
  }) async {
    if (event.id.isEmpty) {
      throw ArgumentError('Event id is missing');
    }

    String? maharajPhotoUrl = event.maharajPhotoUrl;
    if (newMaharajPhoto != null) {
      final fileName = newMaharajPhoto.path.split(Platform.pathSeparator).last;
      final ref = _storage
          .ref()
          .child('maharaj_photos/${event.id}_$fileName');
      await ref.putFile(newMaharajPhoto);
      maharajPhotoUrl = await ref.getDownloadURL();
    }

    final updated = EventModel(
      id: event.id,
      dayNumber: event.dayNumber,
      time: event.time,
      title: event.title,
      maharajName: event.maharajName,
      maharajLocation: event.maharajLocation,
      maharajPhotoUrl: maharajPhotoUrl,
      description: event.description,
      createdAt: event.createdAt,
    );

    await _db
        .collection(AppConstants.eventsCollection)
        .doc(event.id)
        .set(updated.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteEvent(String eventId) async {
    await _db.collection(AppConstants.eventsCollection).doc(eventId).delete();
  }
}

