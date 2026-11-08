import 'package:flutter_test/flutter_test.dart';
import 'package:openlist_mobile/pages/native/tls_page.dart';

void main() {
  const cert = '-----BEGIN CERTIFICATE-----\nMIIB\n-----END CERTIFICATE-----\n';
  const ecKey =
      '-----BEGIN EC PRIVATE KEY-----\nMHc\n-----END EC PRIVATE KEY-----\n';
  const pkcs8 = '-----BEGIN PRIVATE KEY-----\nMIG\n-----END PRIVATE KEY-----\n';

  test('accepts matching PEM blocks', () {
    expect(isPem(cert, key: false), isTrue);
    expect(isPem(ecKey, key: true), isTrue);
    expect(isPem(pkcs8, key: true), isTrue);
  });

  test('rejects wrong kind, truncated or non-PEM input', () {
    expect(isPem(cert, key: true), isFalse);
    expect(isPem(pkcs8, key: false), isFalse);
    expect(isPem('-----BEGIN CERTIFICATE-----\nMIIB\n', key: false), isFalse);
    expect(isPem('{"not":"pem"}', key: false), isFalse);
  });
}
