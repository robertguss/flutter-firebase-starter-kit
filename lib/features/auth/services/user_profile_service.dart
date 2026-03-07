import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_starter_kit/features/auth/models/user_profile.dart';

class UserProfileService {
  UserProfileService({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      firestore.collection('users');

  Future<void> createOrUpdateProfile(
      String uid, Map<String, dynamic> data) async {
    await _users.doc(uid).set(data, SetOptions(merge: true));
  }

  Future<UserProfile?> getProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    final data = doc.data();
    if (data == null) return null;
    return UserProfile.fromMap(uid, data);
  }

  Stream<UserProfile?> profileStream(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      return UserProfile.fromMap(uid, data);
    });
  }

  Future<void> markOnboardingComplete(String uid) async {
    await _users.doc(uid).update({'onboardingComplete': true});
  }

  Future<void> updateFcmToken(String uid, String token) async {
    await _users.doc(uid).update({'fcmToken': token});
  }

  Future<void> clearFcmToken(String uid) async {
    await _users.doc(uid).update({'fcmToken': FieldValue.delete()});
  }

  Future<void> deleteProfile(String uid) async {
    await _users.doc(uid).delete();
  }
}
