/*
 * Copyright (c) 2025 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/widgets.dart';

import '../generated/app_localizations.dart';

export '../generated/app_localizations.dart';

AppLocalizations get appLocalizations {
  return AppLocalizations.of(chewieProvider.rootContext)!;
}

Locale resolveAppLocale(Locale locale) {
  for (final supported in AppLocalizations.supportedLocales) {
    if (supported.languageCode == locale.languageCode &&
        supported.countryCode == locale.countryCode) {
      return supported;
    }
  }
  for (final supported in AppLocalizations.supportedLocales) {
    if (supported.languageCode == locale.languageCode) return supported;
  }
  return AppLocalizations.supportedLocales.first;
}

Locale resolveSystemAppLocale() {
  return resolveAppLocale(
    WidgetsBinding.instance.platformDispatcher.locale,
  );
}

String formatLocalizedYearMonth(int timestamp) {
  if (timestamp < 10000000000) timestamp *= 1000;
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return appLocalizations.yearAndMonth(date.month, date.year);
}
