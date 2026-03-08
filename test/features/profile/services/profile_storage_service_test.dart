import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_starter_kit/features/profile/services/profile_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

class MockReference extends Mock implements Reference {}

class MockUploadTask extends Mock implements UploadTask {}

void main() {
  setUpAll(() {
    registerFallbackValue(ImageSource.gallery);
  });

  late MockFirebaseStorage mockStorage;
  late MockImagePicker mockImagePicker;
  late MockReference mockRef;
  late ProfileStorageService service;

  setUp(() {
    mockStorage = MockFirebaseStorage();
    mockImagePicker = MockImagePicker();
    mockRef = MockReference();
    service = ProfileStorageService(
      storage: mockStorage,
      imagePicker: mockImagePicker,
    );
  });

  group('ProfileStorageService', () {
    group('pickImage', () {
      test('delegates to ImagePicker with correct constraints', () async {
        when(() => mockImagePicker.pickImage(
              source: any(named: 'source'),
              maxWidth: any(named: 'maxWidth'),
              maxHeight: any(named: 'maxHeight'),
              imageQuality: any(named: 'imageQuality'),
            )).thenAnswer((_) async => null);

        await service.pickImage(ImageSource.gallery);

        verify(() => mockImagePicker.pickImage(
              source: ImageSource.gallery,
              maxWidth: 512,
              maxHeight: 512,
              imageQuality: 75,
            )).called(1);
      });

      test('returns null when user cancels', () async {
        when(() => mockImagePicker.pickImage(
              source: any(named: 'source'),
              maxWidth: any(named: 'maxWidth'),
              maxHeight: any(named: 'maxHeight'),
              imageQuality: any(named: 'imageQuality'),
            )).thenAnswer((_) async => null);

        final result = await service.pickImage(ImageSource.camera);
        expect(result, isNull);
      });
    });

    group('deleteAvatar', () {
      test('ignores object-not-found error', () async {
        when(() => mockStorage.ref(any())).thenReturn(mockRef);
        when(() => mockRef.delete()).thenThrow(
          FirebaseException(plugin: 'storage', code: 'object-not-found'),
        );

        // Should not throw
        await service.deleteAvatar('test-uid');
      });

      test('rethrows other errors', () async {
        when(() => mockStorage.ref(any())).thenReturn(mockRef);
        when(() => mockRef.delete()).thenThrow(
          FirebaseException(plugin: 'storage', code: 'unauthorized'),
        );

        expect(
          () => service.deleteAvatar('test-uid'),
          throwsA(isA<FirebaseException>()),
        );
      });
    });
  });
}
