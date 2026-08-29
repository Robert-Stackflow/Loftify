import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/generated/app_localizations_en.dart';

Map<String, Object?> _loadArb(String name) {
  final file = File('lib/l10n/$name');
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

Iterable<String> _messageKeys(Map<String, Object?> arb) {
  return arb.keys.where((key) => !key.startsWith('@'));
}

List<String> _placeholders(Object? value) {
  return RegExp(r'\{([A-Za-z_][A-Za-z0-9_]*)\}')
      .allMatches(value as String)
      .map((match) => match.group(1)!)
      .toList();
}

void main() {
  final localeFiles = <String>[
    'intl_en.arb',
    'intl_zh.arb',
    'intl_zh_CN.arb',
    'intl_zh_TW.arb',
  ];

  test('all locale resources expose the same message keys', () {
    final resources = localeFiles.map(_loadArb).toList();
    final expectedKeys = _messageKeys(resources.first).toSet();

    expect(expectedKeys, hasLength(754));
    for (var index = 1; index < resources.length; index++) {
      expect(
        _messageKeys(resources[index]).toSet(),
        expectedKeys,
        reason: '${localeFiles[index]} must match intl_en.arb',
      );
    }
  });

  test('translated messages preserve every placeholder and its order', () {
    final english = _loadArb('intl_en.arb');
    final traditionalChinese = _loadArb('intl_zh_TW.arb');

    for (final key in _messageKeys(english)) {
      expect(
        _placeholders(english[key]),
        _placeholders(traditionalChinese[key]),
        reason: 'Placeholder mismatch for $key',
      );
    }
  });

  test('English resources contain real English UI copy', () {
    final english = _loadArb('intl_en.arb');
    final messagesWithHanCharacters = _messageKeys(english)
        .where(
          (key) => RegExp(r'[\u3400-\u9fff]').hasMatch(english[key]! as String),
        )
        .toList();

    expect(messagesWithHanCharacters, <String>['fontItemCaptionNonLatin']);

    final localizations = AppLocalizationsEn();
    expect(localizations.home, 'Home');
    expect(localizations.dynamicTab, 'Feed');
    expect(localizations.loginByCaptcha, 'SMS Code Login');
    expect(localizations.grain, 'Grain Lists');
    expect(localizations.exitApp, 'Exit Loftify');
  });
}
