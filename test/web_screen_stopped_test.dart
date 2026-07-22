import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlist_mobile/generated/l10n.dart';
import 'package:openlist_mobile/pages/web/web.dart';
import 'package:openlist_mobile/utils/web_browser_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('disabled browser shows stopped page without WebView',
      (tester) async {
    SharedPreferences.setMockInitialValues({'web_browser_enabled': false});
    await WebBrowserManager.instance.initialize();

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: WebScreen(key: webGlobalKey),
    ));
    await tester.pump();

    expect(find.byType(InAppWebView), findsNothing);
    expect(find.text('The embedded web browser is stopped'), findsOneWidget);
    expect(find.text('Start web browser'), findsOneWidget);
    expect(find.byIcon(Icons.web_asset_off), findsOneWidget);
  });
}
