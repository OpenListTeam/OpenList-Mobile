import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openlist_mobile/utils/driver_localization.dart';

void main() {
  test('English and Chinese ARB catalogs have matching keys', () {
    final en = jsonDecode(File('lib/l10n/intl_en.arb').readAsStringSync())
        as Map<String, dynamic>;
    final zh = jsonDecode(File('lib/l10n/intl_zh.arb').readAsStringSync())
        as Map<String, dynamic>;

    expect(zh.keys.toSet(), en.keys.toSet());
  });

  group('driver metadata translation', () {
    test('translates only exact driver, field, and option identifiers', () {
      const apiOption = 'ASC';

      expect(
        DriverLocalization.fieldLabel(
          languageCode: 'zh',
          driver: 'Aliyundrive',
          field: 'refresh_token',
          fallback: 'refresh_token',
        ),
        '刷新令牌',
      );
      expect(
        DriverLocalization.optionLabel(
          languageCode: 'zh',
          driver: 'Aliyundrive',
          field: 'order_direction',
          option: apiOption,
        ),
        '升序',
      );
      expect(apiOption, 'ASC');
      expect(
        DriverLocalization.fieldLabel(
          languageCode: 'zh',
          driver: 'ThirdPartyDriver',
          field: 'refresh_token',
          fallback: 'refresh_token',
        ),
        'refresh_token',
      );
      expect(
        DriverLocalization.optionLabel(
          languageCode: 'en',
          driver: 'Aliyundrive',
          field: 'order_direction',
          option: apiOption,
        ),
        apiOption,
      );
    });

    test('leaves unknown help and alert metadata unchanged', () {
      expect(
        DriverLocalization.fieldLabel(
          languageCode: 'zh',
          driver: 'S3',
          field: 'custom.help',
          fallback: 'Provider-specific instructions',
        ),
        'Provider-specific instructions',
      );
      expect(
        DriverLocalization.alertText(
          languageCode: 'zh',
          driver: 'ThirdPartyDriver',
          text: 'Provider maintenance notice',
        ),
        'Provider maintenance notice',
      );
    });
  });
}
