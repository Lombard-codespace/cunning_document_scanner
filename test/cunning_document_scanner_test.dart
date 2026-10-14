import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';

import 'mocks/mock_permission_handler_platform.dart';

void main() {
  group('CunningDocumentScanner permission denied', () {
    setUp(() {
      PermissionHandlerPlatform.instance = MockPermissionHandlerPlatform(
          permissionStatus: PermissionStatus.denied);
    });

    test('getPictures with denied permission', () async {
      expect(
        () async => await CunningDocumentScanner.getPictures(),
        throwsA(isA<CunningDocumentScannerException>()
            .having((e) => e.code, 'code', 'permission_denied')
            .having(
                (e) => e.message, 'message', 'Camera permission not granted')),
      );
    });
  });

  group('CunningDocumentScanner permission permanently denied', () {
    setUp(() {
      PermissionHandlerPlatform.instance = MockPermissionHandlerPlatform(
          permissionStatus: PermissionStatus.permanentlyDenied);
    });

    test('getPictures with permanently denied permission', () async {
      expect(
        () async => await CunningDocumentScanner.getPictures(),
        throwsA(isA<CunningDocumentScannerException>()
            .having((e) => e.code, 'code', 'permission_denied')
            .having(
                (e) => e.message, 'message', 'Camera permission not granted')),
      );
    });
  });

  group('CunningDocumentScanner Plugin exceptions', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      PermissionHandlerPlatform.instance = MockPermissionHandlerPlatform();
    });

    test('getPictures with MissingPluginException', () async {
      expect(() async => await CunningDocumentScanner.getPictures(),
          throwsA(isA<MissingPluginException>()));
    });
  });

  group('CunningDocumentScanner granted permission', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      PermissionHandlerPlatform.instance = MockPermissionHandlerPlatform();
    });

    void loadPlatformChannel(WidgetTester tester, List<String> result) {
      MethodChannel channel = const MethodChannel('cunning_document_scanner');

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) => Future.value(result),
      );
    }

    testWidgets('getPictures empty result', (WidgetTester tester) async {
      final List<String> emptyResult = [];
      loadPlatformChannel(tester, emptyResult);
      final result = await CunningDocumentScanner.getPictures();
      expect(result, emptyResult);
    });

    testWidgets('getPictures multiple result', (WidgetTester tester) async {
      final List<String> fakeResult = ['fake_url1', 'fake_url2', 'fake_url3'];
      loadPlatformChannel(tester, fakeResult);
      final result = await CunningDocumentScanner.getPictures();
      expect(result, fakeResult);
    });

    testWidgets('getPictures passes iOS scanner options',
        (WidgetTester tester) async {
      MethodCall? receivedCall;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('cunning_document_scanner'),
        (MethodCall methodCall) {
          receivedCall = methodCall;
          return Future.value(<String>[]);
        },
      );

      await CunningDocumentScanner.getPictures(
        iosScannerOptions: const IosScannerOptions(
          imageFormat: IosImageFormat.jpg,
          jpgCompressionQuality: 0.8,
          maxImageDimension: 2400,
        ),
      );

      final iosOptions =
          (receivedCall!.arguments as Map)['iosScannerOptions'] as Map;
      expect(iosOptions['imageFormat'], 'jpg');
      expect(iosOptions['jpgCompressionQuality'], 0.8);
      expect(iosOptions['maxImageDimension'], 2400);
    });

    testWidgets('getPictures omits maxImageDimension when not set',
        (WidgetTester tester) async {
      MethodCall? receivedCall;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('cunning_document_scanner'),
        (MethodCall methodCall) {
          receivedCall = methodCall;
          return Future.value(<String>[]);
        },
      );

      await CunningDocumentScanner.getPictures(
        iosScannerOptions: const IosScannerOptions(),
      );

      final iosOptions =
          (receivedCall!.arguments as Map)['iosScannerOptions'] as Map;
      expect(iosOptions.containsKey('maxImageDimension'), isFalse);
    });
  });
}
