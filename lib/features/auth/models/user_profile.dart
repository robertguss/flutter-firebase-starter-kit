import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool onboardingComplete;
  final String? fcmToken;
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.onboardingComplete = false,
    this.fcmToken,
    required this.createdAt,
  });

  // uid passed separately because Firestore doc IDs are not stored in doc data
  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      email: map['email'] as String?,
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      onboardingComplete: map['onboardingComplete'] as bool? ?? false,
      fcmToken: map['fcmToken'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'onboardingComplete': onboardingComplete,
        'fcmToken': fcmToken,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  UserProfile copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    bool? onboardingComplete,
    String? fcmToken,
  }) =>
      UserProfile(
        uid: uid,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        photoUrl: photoUrl ?? this.photoUrl,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        fcmToken: fcmToken ?? this.fcmToken,
        createdAt: createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          uid == other.uid &&
          email == other.email &&
          displayName == other.displayName &&
          photoUrl == other.photoUrl &&
          onboardingComplete == other.onboardingComplete &&
          fcmToken == other.fcmToken &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        uid,
        email,
        displayName,
        photoUrl,
        onboardingComplete,
        fcmToken,
        createdAt,
      );
}
