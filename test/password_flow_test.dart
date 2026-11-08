import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:openlist_mobile/api/session.dart';
import 'package:openlist_mobile/generated/l10n.dart';
import 'package:openlist_mobile/pages/openlist/pwd_edit_dialog.dart';
import 'package:openlist_mobile/screens/settings_screen.dart';
import 'package:openlist_mobile/utils/language_controller.dart';
import 'package:openlist_mobile/utils/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _localized(Widget child) => GetMaterialApp(
  localizationsDelegates: const [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: S.delegate.supportedLocales,
  locale: const Locale('en'),
  home: child,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    await OpenListSession.instance.disconnectLocal();
  });

  tearDown(Get.reset);

  testWidgets('local password entry is visible without a session', (
    tester,
  ) async {
    Get.put(LanguageController());
    Get.put(ThemeController());

    await tester.pumpWidget(_localized(const SettingsScreen()));
    await tester.pump();

    expect(find.text(S.current.changeAdminPassword), findsOneWidget);
    expect(find.text(S.current.coreSettings), findsNothing);
  });

  testWidgets('password dialog waits for the async result before closing', (
    tester,
  ) async {
    final result = Completer<bool>();
    await tester.pumpWidget(
      _localized(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (_) => PwdEditDialog(onConfirm: (_) => result.future),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'new-password');
    await tester.pump();
    final confirmButton = find.widgetWithText(FilledButton, S.current.confirm);
    expect(tester.widget<FilledButton>(confirmButton).onPressed, isNotNull);
    await tester.tap(confirmButton);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(PwdEditDialog), findsOneWidget);

    result.complete(true);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(PwdEditDialog), findsNothing);
  });
}
