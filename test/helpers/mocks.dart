import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_starter_kit/features/auth/services/auth_service.dart';
import 'package:flutter_starter_kit/features/auth/services/user_profile_service.dart';
import 'package:flutter_starter_kit/features/paywall/services/purchases_service.dart';
import 'package:flutter_starter_kit/features/profile/services/profile_storage_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

// Auth
class MockAuthService extends Mock implements AuthService {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

// Profile
class MockUserProfileService extends Mock implements UserProfileService {}

// Purchases
class MockPurchasesService extends Mock implements PurchasesService {}

class MockCustomerInfo extends Mock implements CustomerInfo {}

class MockEntitlementInfos extends Mock implements EntitlementInfos {}

class MockEntitlementInfo extends Mock implements EntitlementInfo {}

class MockOfferings extends Mock implements Offerings {}

class MockOffering extends Mock implements Offering {}

class MockPackage extends Mock implements Package {}

class MockStoreProduct extends Mock implements StoreProduct {}

// Profile Storage
class MockProfileStorageService extends Mock implements ProfileStorageService {}

class MockFirebaseStorage extends Mock implements FirebaseStorage {}

class MockImagePicker extends Mock implements ImagePicker {}

// Notifications
class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}
