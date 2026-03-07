import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileService {
  UserProfileService({FirebaseFirestore? firestore})
    : firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      firestore.collection('users');

  Future<void> createProfile({
    required String uid,
    required String? displayName,
    required String? email,
    required String? photoUrl,
  }) async {
    await _users.doc(uid).set({
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'onboardingComplete': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.data();
  }

  Future<void> markOnboardingComplete(String uid) async {
    await _users.doc(uid).update({'onboardingComplete': true});
  }

  Future<void> deleteProfile(String uid) async {
    await _users.doc(uid).delete();
  }
}
