import 'dart:collection';
import 'dart:convert';
import 'dart:developer';
import 'dart:io' show Platform;

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
    // iOS specific: Enable page caching and state preservation
    cacheEnabled: true,
    sharedCookiesEnabled: true,
    limitsNavigationsToAppBoundDomains: Platform.isIOS,
    // Enable disk and memory cache for better state preservation
    cacheMode: CacheMode.LOAD_DEFAULT,
    // Prevent WebView from being suspended in background
    allowsBackForwardNavigationGestures: true,
    // iOS: Suppress rendering until content is loaded
    suppressesIncrementalRendering: false,
  );

  double _progress = 0;
  String _url = "http://localhost:5244";
  bool _canGoBack = false;
  bool _isLoading = false;

  static const int _blobChunkSize = 128 * 1024;
  static final UnmodifiableListView<UserScript> _blobDownloadScripts =
      UnmodifiableListView([
    UserScript(
      source: r'''
(() => {
  if (!["localhost", "127.0.0.1", "::1"].includes(location.hostname)) return;
  if (window.__openListBlobDownloads) return;

  const downloads = new Map();
  const originalClick = HTMLAnchorElement.prototype.click;
  const originalRevokeObjectURL = URL.revokeObjectURL.bind(URL);

  const release = (url) => {
    const entry = downloads.get(url);
    if (entry) clearTimeout(entry.timeout);
    downloads.delete(url);
    originalRevokeObjectURL(url);
  };

  HTMLAnchorElement.prototype.click = function() {
    const url = this.href;
    if (this.download && url.startsWith("blob:")) {
      const previous = downloads.get(url);
      if (previous) clearTimeout(previous.timeout);

      const entry = {
        blob: fetch(url).then((response) => response.blob()),
        timeout: null,
      };
      entry.timeout = setTimeout(() => release(url), 30000);
      downloads.set(url, entry);
    }
    return originalClick.call(this);
  };

  URL.revokeObjectURL = (url) => {
    if (!downloads.has(url)) originalRevokeObjectURL(url);
  };

  window.__openListBlobDownloads = downloads;
  window.__openListBlobTransfers = downloads;
  window.__openListReleaseBlobDownload = release;
})();
''',
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    ),
  ]);

  static const Set<String> _inAppSafeSchemes = {
    "about",
    "data",
    "file",
  };

  bool _isLoopbackHost(String host) {
    final normalized = host.toLowerCase();
    return normalized == "localhost" ||
        normalized == "127.0.0.1" ||
        normalized == "::1";
  }

  bool _isAllowedInAppNavigation(Uri uri) {
    final scheme = uri.scheme.toLowerCase();

    if (_inAppSafeSchemes.contains(scheme)) {
      return true;
    }

    if (scheme == "http" || scheme == "https") {
      if (!Platform.isIOS) {
        return true;
      }
      return _isLoopbackHost(uri.host);
    }

    return false;
  }

  Future<void> _openExternalUri(String uriString) async {
    final silentMode = await NativeBridge.appConfig.isSilentJumpAppEnabled();
    if (silentMode) {
      NativeCommon().startActivityFromUri(uriString);
      return;
    }

    if (!mounted) return;

    Get.showSnackbar(GetSnackBar(
        message: S.current.jumpToOtherApp,
        duration: const Duration(seconds: 5),
        mainButton: TextButton(
          onPressed: () {
            NativeCommon().startActivityFromUri(uriString);
          },
          child: Text(S.current.goTo),
        )));
  }

  Future<Map<String, dynamic>> _initializeBlobTransfer(
    InAppWebViewController controller,
    String url,
  ) async {
    final result = await controller.callAsyncJavaScript(
      functionBody: r'''
const entry = window.__openListBlobDownloads?.get(url);
if (!entry) throw "Blob download is no longer available";

clearTimeout(entry.timeout);
const blob = await entry.blob;
window.__openListBlobTransfers.set(url, blob);
return {size: blob.size, type: blob.type};
''',
      arguments: {"url": url},
      contentWorld: ContentWorld.PAGE,
    );

    if (result?.error != null) {
      throw StateError(result!.error!);
    }
    if (result?.value is! Map) {
      throw StateError("Failed to initialize Blob download");
    }
    return Map<String, dynamic>.from(result!.value as Map);
  }

  Future<List<int>> _readBlobChunk(
    InAppWebViewController controller,
    String url,
    int offset,
  ) async {
    final result = await controller.callAsyncJavaScript(
      functionBody: r'''
const blob = window.__openListBlobTransfers?.get(url);
if (!blob) throw "Blob download is no longer available";

const bytes = new Uint8Array(
  await blob.slice(offset, offset + chunkSize).arrayBuffer(),
);
let binary = "";
for (let i = 0; i < bytes.length; i += 0x8000) {
  binary += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
}
return btoa(binary);
''',
      arguments: {
        "url": url,
        "offset": offset,
        "chunkSize": _blobChunkSize,
      },
      contentWorld: ContentWorld.PAGE,
    );

    if (result?.error != null) {
      throw StateError(result!.error!);
    }
    if (result?.value is! String) {
      throw StateError("Failed to read Blob download");
    }
    return base64Decode(result!.value as String);
  }

  Future<void> _releaseBlobTransfer(
    InAppWebViewController controller,
    String url,
  ) async {
    await controller.callAsyncJavaScript(
      functionBody: r'''
window.__openListBlobTransfers?.delete(url);
window.__openListReleaseBlobDownload?.(url);
''',
      arguments: {"url": url},
      contentWorld: ContentWorld.PAGE,
    );
  }

  Future<void> _downloadBlob(
    InAppWebViewController controller,
    DownloadStartRequest request,
  ) async {
    final url = request.url.toString();
    try {
      final metadata = await _initializeBlobTransfer(controller, url);
      final size = (metadata["size"] as num).toInt();
      final saved = await DownloadManager.saveFileInBackground(
        source: url,
        filename: request.suggestedFilename,
        totalBytes: size,
        readChunk: (offset) => _readBlobChunk(controller, url, offset),
      );
      if (!saved) return;
    } catch (error) {
      log("Blob download failed: $error");
      Get.showSnackbar(GetSnackBar(
        message: S.current.downloadFailedFile(
          request.suggestedFilename ?? "download",
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
      ));
    } finally {
      try {
        await _releaseBlobTransfer(controller, url);
      } catch (error) {
        log("Failed to release Blob download: $error");
      }
    }
  }

  onClickNavigationBar() {
    log("onClickNavigationBar");
    _webViewController?.reload();
  }

  @override
  void initState() {
    super.initState();
    // Register lifecycle observer to handle app state changes
    WidgetsBinding.instance.addObserver(this);
    
    // Get OpenList HTTP port
    Android()
        .getOpenListHttpPort()
        .then((port) {
          setState(() {
            _url = "http://localhost:$port";
          });
          log("OpenList URL set to: $_url");
        })
        .catchError((error) {
          log("Failed to get OpenList port: $error");
        });

    // Wait a bit for service to be ready before loading
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _webViewController == null) {
        // Will be initialized when WebView is created
        log("WebView will initialize with URL: $_url");
      }
    });
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
                initialUserScripts: _blobDownloadScripts,
                initialUrlRequest: URLRequest(url: WebUri(_url)),
                onWebViewCreated: (InAppWebViewController controller) {
                  _webViewController = controller;
                  log("WebView created, loading URL: $_url");
                },
                onLoadStart: (InAppWebViewController controller, Uri? url) {
                  log("onLoadStart $url");
                  setState(() {
                    _progress = 0;
                    _isLoading = true;
                  });
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  log("shouldOverrideUrlLoading ${navigationAction.request.url}");

                  final uri = navigationAction.request.url;
                  if (uri == null) {
                    return NavigationActionPolicy.CANCEL;
                  }

                  if (_isAllowedInAppNavigation(uri)) {
                    return NavigationActionPolicy.ALLOW;
                  }

                  final scheme = uri.scheme.toLowerCase();
                  if (Platform.isIOS && scheme == "javascript") {
                    log("Blocked javascript navigation on iOS: ${uri.toString()}");
                    return NavigationActionPolicy.CANCEL;
                  }

                  await _openExternalUri(uri.toString());
                  return NavigationActionPolicy.CANCEL;
                },
                onReceivedError: (controller, request, error) async {
                  log("WebView error: ${error.description}");
                  
                  // Check if OpenList service is running
                  try {
                    if (!await Android().isRunning()) {
                      log("Service not running, attempting to start...");
                      await Android().startService();

                      // Wait for service to start and retry
                      for (int i = 0; i < 3; i++) {
                        await Future.delayed(const Duration(milliseconds: 500));
                        if (await Android().isRunning()) {
                          log("Service started, reloading WebView");
                          _webViewController?.reload();
                          break;
                        }
                      }
                    }
                  } catch (e) {
                    log("Failed to handle WebView error: $e");
                  }
                },
                onDownloadStartRequest: (controller, request) async {
                  final isBlob = request.url.scheme == "blob";
                  Get.showSnackbar(GetSnackBar(
                    title: S.of(context).downloadThisFile,
                    message: request.suggestedFilename ??
                        request.contentDisposition ??
                        request.toString(),
                    duration: const Duration(seconds: 5),
                    mainButton: Column(children: [
                      TextButton(
                        onPressed: () async {
                          Get.closeCurrentSnackbar();
                          if (isBlob) {
                            await _downloadBlob(controller, request);
                          } else {
                          DownloadManager.downloadFileInBackground(
                              url: request.url.toString(),
                              filename: request.suggestedFilename,
                          );
                          }
                        },
                        child: Text(S.of(context).directDownload),
                      ),
                      if (!isBlob) ...[
                      TextButton(
                        onPressed: () {
                            IntentUtils.getUrlIntent(request.url.toString())
                              .launchChooser(S.of(context).selectAppToOpen);
                        },
                        child: Text(S.of(context).selectAppToOpen),
                      ),
                      TextButton(
                        onPressed: () {
                            IntentUtils.getUrlIntent(request.url.toString())
                                .launch();
                        },
                        child: Text(S.of(context).browserDownload),
                      ),
                      ],
                    ]),
                    onTap: isBlob
                        ? null
                        : (_) {
                            Clipboard.setData(ClipboardData(
                              text: request.url.toString(),
                            ));
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
                  log("onLoadStop $url");
                  setState(() {
                    _progress = 0;
                    _isLoading = false;
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
