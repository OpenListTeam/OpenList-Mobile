import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:openlist_mobile/generated/l10n.dart';
import 'package:openlist_mobile/generated_api.dart';
import 'package:openlist_mobile/screens/files_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefix = 'dev.flutter.pigeon.openlist_mobile.ServerApi.';

/// Answers ServerApi Pigeon calls the way a host with a stopped core would.
void _mockServerApi(List<String> calls) {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const codec = ServerApi.pigeonChannelCodec;
  for (final name in ['getStatus', 'start', 'getLocalToken']) {
    messenger.setMockMessageHandler('$_prefix$name', (data) async {
      calls.add(name);
      final Object? reply = switch (name) {
        'getStatus' => ServerStatus(
            running: false,
            mode: 'local',
            httpPort: 5244,
            httpsPort: -1,
            forceHttps: false,
            addresses: const [],
            manuallyStopped: true,
          ),
        'getLocalToken' => '',
        _ => null,
      };
      return codec.encodeMessage(<Object?>[reply]);
    });
  }
}

Widget _app() => GetMaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      locale: const Locale('en'),
      home: const FilesScreen(),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('files screen offers to start a stopped local core',
      (tester) async {
    final calls = <String>[];
    _mockServerApi(calls);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text(S.current.connectToServer), findsOneWidget);
    expect(calls, contains('getStatus'));

    await tester.tap(find.text(S.current.connectToServer));
    await tester.pumpAndSettle();
    expect(calls, contains('start'));
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
