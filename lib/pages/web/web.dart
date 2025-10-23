import 'dart:developer';

import 'package:openlist_mobile/contant/native_bridge.dart';
import 'package:openlist_mobile/generated_api.dart';
import 'package:openlist_mobile/utils/intent_utils.dart';
import 'package:openlist_mobile/utils/download_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

import '../../generated/l10n.dart';

GlobalKey<WebScreenState> webGlobalKey = GlobalKey();

class WebScreen extends StatefulWidget {
  const WebScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return WebScreenState();
  }
}

class WebScreenState extends State<WebScreen> with WidgetsBindingObserver {
  InAppWebViewController? _webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
    allowsInlineMediaPlayback: true,
    allowBackgroundAudioPlaying: true,
    iframeAllowFullscreen: true,
    javaScriptEnabled: true,
    mediaPlaybackRequiresUserGesture: false,
    useShouldOverrideUrlLoading: true,
  );

  double _progress = 0;
  String _url = "http://localhost:5244";
  bool _canGoBack = false;

  onClickNavigationBar() {
    log("onClickNavigationBar");
    _webViewController?.reload();
  }

  @override
  void initState() {
    super.initState();
    // Register lifecycle observer to handle app state changes
    WidgetsBinding.instance.addObserver(this);
    
    Android()
        .getOpenListHttpPort()
        .then((port) => {_url = "http://localhost:$port"});

    // NativeEvent().addServiceStatusListener((isRunning) {
    //   if (isRunning) _webViewController?.reload();
    // });
  }

  @override
  void dispose() {
    // Remove lifecycle observer when widget is disposed
    WidgetsBinding.instance.removeObserver(this);
    _webViewController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    log("App lifecycle state changed: $state");
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App returned to foreground, WebView should be active
        log("App resumed, WebView is active");
        _webViewController?.resume();
        break;
      case AppLifecycleState.paused:
        // App entered background, ensure WebView state is preserved
        log("App paused, WebView entering background");
        // Note: Do not pause WebView to keep background tasks running
        // The UIBackgroundModes in Info.plist allows WebKit processes to continue
        break;
      case AppLifecycleState.inactive:
        // App transitioning states (e.g., incoming call, app switcher)
        log("App inactive");
        break;
      case AppLifecycleState.detached:
        // App is detached from UI
        log("App detached");
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        log("App hidden");
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: !_canGoBack,
        onPopInvoked: (didPop) async {
          log("onPopInvoked $didPop");
          if (didPop) return;
          _webViewController?.goBack();
        },
        child: Scaffold(
          body: Column(children: <Widget>[
            SizedBox(height: MediaQuery.of(context).padding.top),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            Expanded(
              child: InAppWebView(
                initialSettings: settings,
                initialUrlRequest: URLRequest(url: WebUri(_url)),
                onWebViewCreated: (InAppWebViewController controller) {
                  _webViewController = controller;
                },
                onLoadStart: (InAppWebViewController controller, Uri? url) {
                  log("onLoadStart $url");
                  setState(() {
                    _progress = 0;
                  });
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  log("shouldOverrideUrlLoading ${navigationAction.request.url}");

                  var uri = navigationAction.request.url!;
                  if (![
                    "http",
                    "https",
                    "file",
                    "chrome",
                    "data",
                    "javascript",
                    "about"
                  ].contains(uri.scheme)) {
                    log("shouldOverrideUrlLoading ${uri.toString()}");
                    final silentMode =
                        await NativeBridge.appConfig.isSilentJumpAppEnabled();
                    if (silentMode) {
                      NativeCommon().startActivityFromUri(uri.toString());
                    } else {
                      Get.showSnackbar(GetSnackBar(
                          message: S.current.jumpToOtherApp,
                          duration: const Duration(seconds: 5),
                          mainButton: TextButton(
                            onPressed: () {
                              NativeCommon()
                                  .startActivityFromUri(uri.toString());
                            },
                            child: Text(S.current.goTo),
                          )));
                    }

                    return NavigationActionPolicy.CANCEL;
                  }

                  return NavigationActionPolicy.ALLOW;
                },
                onReceivedError: (controller, request, error) async {
                  if (!await Android().isRunning()) {
                    await Android().startService();

                    for (int i = 0; i < 3; i++) {
                      await Future.delayed(const Duration(milliseconds: 500));
                      if (await Android().isRunning()) {
                        _webViewController?.reload();
                        break;
                      }
                    }
                  }
                },
                onDownloadStartRequest: (controller, url) async {
                  Get.showSnackbar(GetSnackBar(
                    title: S.of(context).downloadThisFile,
                    message: url.suggestedFilename ??
                        url.contentDisposition ??
                        url.toString(),
                    duration: const Duration(seconds: 5),
                    mainButton: Column(children: [
                      TextButton(
                        onPressed: () async {
                          Get.closeCurrentSnackbar();
                          // 使用内置下载管理器后台下载
                          DownloadManager.downloadFileInBackground(
                            url: url.url.toString(),
                            filename: url.suggestedFilename,
                          );
                        },
                        child: Text(S.of(context).directDownload),
                      ),
                      TextButton(
                        onPressed: () {
                          IntentUtils.getUrlIntent(url.url.toString())
                              .launchChooser(S.of(context).selectAppToOpen);
                        },
                        child: Text(S.of(context).selectAppToOpen),
                      ),
                      TextButton(
                        onPressed: () {
                          IntentUtils.getUrlIntent(url.url.toString()).launch();
                        },
                        child: Text(S.of(context).browserDownload),
                      ),
                    ]),
                    onTap: (_) {
                      Clipboard.setData(
                          ClipboardData(text: url.url.toString()));
                      Get.closeCurrentSnackbar();
                      Get.showSnackbar(GetSnackBar(
                        message: S.of(context).copiedToClipboard,
                        duration: const Duration(seconds: 1),
                      ));
                    },
                  ));
                },
                onLoadStop:
                    (InAppWebViewController controller, Uri? url) async {
                  setState(() {
                    _progress = 0;
                  });
                },
                onProgressChanged:
                    (InAppWebViewController controller, int progress) {
                  setState(() {
                    _progress = progress / 100;
                    if (_progress == 1) _progress = 0;
                  });
                  controller.canGoBack().then((value) => setState(() {
                        _canGoBack = value;
                      }));
                },
                onUpdateVisitedHistory: (InAppWebViewController controller,
                    WebUri? url, bool? isReload) {
                  _url = url.toString();
                },
              ),
            ),
          ]),
        ));
  }
}
