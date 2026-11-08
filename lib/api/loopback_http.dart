import 'dart:io';

/// True for hosts that resolve to this device only.
bool isLoopbackHost(String host) {
  final h = host.toLowerCase();
  if (h == 'localhost' || h == '::1' || h == '[::1]') return true;
  final ip = InternetAddress.tryParse(h);
  return ip != null && ip.isLoopback;
}

/// Trusts the embedded core's self-signed certificate on loopback only.
///
/// Installed globally so Dio, Image.network and the download manager all share
/// one policy; certificates for any other host are still fully validated.
class LoopbackHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (_, host, __) => isLoopbackHost(host);
  }
}
