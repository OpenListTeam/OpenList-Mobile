import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:openlist_mobile/generated/l10n.dart';
import 'package:openlist_mobile/generated_api.dart';
import 'package:openlist_mobile/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefix = 'dev.flutter.pigeon.openlist_mobile.ServerApi.';

void _mockHomeApi(
  List<String> calls, {
  bool publicBlocked = false,
  bool running = true,
  bool restartFails = false,
}) {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const codec = ServerApi.pigeonChannelCodec;
  final handlers = <String, Object? Function(List<Object?>)>{
    'getStatus': (_) => ServerStatus(
      running: running,
      mode: 'local',
      httpPort: 5244,
      httpsPort: -1,
      forceHttps: false,
      addresses: const ['127.0.0.1'],
      manuallyStopped: false,
    ),
    'getMode': (_) => 'local',
    'getSecurityReport': (_) => jsonEncode({'blocked': publicBlocked}),
    'setMode': (args) {
      calls.add('setMode:${args.single}');
      return null;
    },
    'restart': (_) {
      calls.add('restart');
      if (restartFails) throw PlatformException(code: 'restart-failed');
      return null;
    },
  };

  for (final entry in handlers.entries) {
    messenger.setMockMessageHandler('$_prefix${entry.key}', (data) async {
      final args = codec.decodeMessage(data) as List<Object?>? ?? <Object?>[];
      final Object? reply = entry.value(args);
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
  home: const HomeScreen(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('blocks public mode when a required security check fails', (
    tester,
  ) async {
    final calls = <String>[];
    _mockHomeApi(calls, publicBlocked: true);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Network Mode').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.modePublic));
    await tester.pumpAndSettle();

    expect(find.text(S.current.publicBlocked), findsOneWidget);
    expect(calls, isEmpty);
  });

  testWidgets('does not save mode when restart confirmation is cancelled', (
    tester,
  ) async {
    final calls = <String>[];
    _mockHomeApi(calls);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Network Mode').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.modeLan));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.cancel));
    await tester.pumpAndSettle();

    expect(calls, isEmpty);
  });

  testWidgets('saves mode and restarts a running server after confirmation', (
    tester,
  ) async {
    final calls = <String>[];
    _mockHomeApi(calls);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Network Mode').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.modeLan));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.confirm));
    await tester.pumpAndSettle();

    expect(calls, ['setMode:lan', 'restart']);
  });

  testWidgets('changes a stopped server mode without restarting', (
    tester,
  ) async {
    final calls = <String>[];
    _mockHomeApi(calls, running: false);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Network Mode').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.modeLan));
    await tester.pumpAndSettle();

    expect(calls, ['setMode:lan']);
  });

  testWidgets('home downloads action opens the Downloads tab', (tester) async {
    _mockHomeApi([]);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(S.current.downloads));
    await tester.pumpAndSettle();

    expect(find.text(S.current.transfers), findsOneWidget);
    expect(find.text(S.current.downloads), findsOneWidget);
  });

  testWidgets('rolls back the saved mode when restart fails', (tester) async {
    final calls = <String>[];
    _mockHomeApi(calls, restartFails: true);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Network Mode').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.modeLan));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.confirm));
    await tester.pumpAndSettle();

    expect(calls, ['setMode:lan', 'restart', 'setMode:local']);
    expect(find.text(S.current.serviceRestartFailed), findsOneWidget);
  });
}
