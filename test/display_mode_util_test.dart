import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loftify/Utils/display_mode_util.dart';

void main() {
  const automatic = DisplayMode.auto;
  const mode120 = DisplayMode(
    id: 1,
    width: 1200,
    height: 2670,
    refreshRate: 120,
  );
  const mode60 = DisplayMode(
    id: 2,
    width: 1200,
    height: 2670,
    refreshRate: 60,
  );
  const mode90 = DisplayMode(
    id: 3,
    width: 1200,
    height: 2670,
    refreshRate: 90,
  );
  const tablet144 = DisplayMode(
    id: 4,
    width: 2560,
    height: 1600,
    refreshRate: 144,
  );

  test('stable signature restores the same mode after list reordering', () {
    final encoded = DisplayModePreference.encode(mode90);
    final restored = DisplayModePreference.resolve(
      modes: const [automatic, mode60, mode120, mode90],
      activeMode: mode60,
      encodedMode: encoded,
    );

    expect(restored, mode90);
  });

  test('legacy index is resolved against the original plugin order', () {
    final restored = DisplayModePreference.resolve(
      modes: const [automatic, mode120, mode60, mode90],
      activeMode: mode60,
      legacyIndex: 3,
    );

    expect(restored, mode90);
  });

  test('default selects highest refresh rate at the active resolution', () {
    final restored = DisplayModePreference.resolve(
      modes: const [automatic, tablet144, mode60, mode90, mode120],
      activeMode: mode60,
    );

    expect(restored, mode120);
  });

  test('unsupported saved mode safely falls back to the current resolution',
      () {
    final restored = DisplayModePreference.resolve(
      modes: const [automatic, mode60, mode90],
      activeMode: mode60,
      encodedMode: '1080x2400@165.000',
    );

    expect(restored, mode90);
  });

  test('nearby fractional rate restores the saved physical mode', () {
    const fractional60 = DisplayMode(
      id: 5,
      width: 1200,
      height: 2670,
      refreshRate: 59.94,
    );
    final restored = DisplayModePreference.resolve(
      modes: const [automatic, mode120, mode90, fractional60],
      activeMode: mode120,
      encodedMode: '1200x2670@60.000',
    );

    expect(restored, fractional60);
  });

  test('distant unsupported rate still falls back to highest refresh rate', () {
    final restored = DisplayModePreference.resolve(
      modes: const [automatic, mode60, mode90, mode120],
      activeMode: mode60,
      encodedMode: '1200x2670@75.000',
    );

    expect(restored, mode120);
  });

  test('mode menu is deduplicated and ordered by refresh rate', () {
    final ordered = DisplayModePreference.ordered(
      const [mode60, mode120, automatic, mode90, mode120],
    );

    expect(ordered, const [automatic, mode120, mode90, mode60]);
    expect(
      DisplayModePreference.label(
        ordered.first,
        automaticLabel: 'Follow system',
      ),
      'Follow system',
    );
    expect(
      DisplayModePreference.label(mode120, automaticLabel: 'Follow system'),
      '1200 × 2670 · 120 Hz',
    );
  });

  test('surface refresh-rate hint preserves exact rate and clears for auto',
      () {
    const fractionalMode = DisplayMode(
      id: 6,
      width: 1080,
      height: 2400,
      refreshRate: 119.88,
    );

    expect(DisplayModeController.surfaceRefreshRate(fractionalMode), 119.88);
    expect(DisplayModeController.surfaceRefreshRate(automatic), 0);
  });
}
