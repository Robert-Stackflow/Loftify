import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

import '../Design/loftify_surfaces.dart';

class ProfileStatisticData {
  const ProfileStatisticData({
    required this.title,
    required this.count,
    this.onTap,
  });

  final String title;
  final int? count;
  final VoidCallback? onTap;
}

class ProfileOverviewCard extends StatelessWidget {
  const ProfileOverviewCard({
    super.key,
    required this.statistics,
    this.backgroundColor,
    this.foregroundColor,
    this.radius = 14,
  });

  final List<ProfileStatisticData> statistics;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final effectiveForeground =
        foregroundColor ?? Theme.of(context).colorScheme.onSurface;
    return LoftifyCard(
      backgroundColor: backgroundColor,
      radius: radius,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(
                  Theme.of(context).textTheme.labelSmall?.fontSize ?? 11) /
              (Theme.of(context).textTheme.labelSmall?.fontSize ?? 11);
          final useTwoRows = statistics.length > 2 &&
              (constraints.maxWidth < 280 || textScale > 1.45);
          if (useTwoRows) {
            final itemWidth = constraints.maxWidth / 2;
            return Wrap(
              children: [
                for (final statistic in statistics)
                  SizedBox(
                    width: itemWidth,
                    child: _ProfileStatisticItem(
                      data: statistic,
                      foregroundColor: effectiveForeground,
                      radius: radius,
                    ),
                  ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var index = 0; index < statistics.length; index++) ...[
                Expanded(
                  child: _ProfileStatisticItem(
                    data: statistics[index],
                    foregroundColor: effectiveForeground,
                    radius: radius,
                  ),
                ),
                if (index != statistics.length - 1)
                  SizedBox(
                    height: 42,
                    child: VerticalDivider(
                      width: 1,
                      thickness: 0.6,
                      color: effectiveForeground.withValues(alpha: 0.22),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ProfileStatisticItem extends StatelessWidget {
  const _ProfileStatisticItem({
    required this.data,
    required this.foregroundColor,
    required this.radius,
  });

  final ProfileStatisticData data;
  final Color foregroundColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final formatted = _formatCount(context, data.count ?? 0);
    final count = formatted['count']?.toString() ?? '0';
    final scale = formatted['scale']?.toString();
    return Semantics(
      button: data.onTap != null,
      label: '${data.title} ${data.count ?? 0}',
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 24,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: data.count == null ? '-' : count),
                        if (data.count != null && scale != null)
                          TextSpan(
                            text: ' $scale',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: foregroundColor),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: foregroundColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                data.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: foregroundColor.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, String> _formatCount(BuildContext context, int count) {
    final languageCode = Localizations.localeOf(context).languageCode;
    if (const {'zh', 'ja', 'ko'}.contains(languageCode)) {
      return NumberUtil.formatCountToMap(count).map(
        (key, value) => MapEntry(key, value.toString()),
      );
    }

    const units = <({int threshold, String suffix})>[
      (threshold: 1000000000, suffix: 'B'),
      (threshold: 1000000, suffix: 'M'),
      (threshold: 1000, suffix: 'K'),
    ];
    for (final unit in units) {
      if (count >= unit.threshold) {
        final value = count / unit.threshold;
        final digits = value >= 100 ? 0 : 1;
        final compact = value.toStringAsFixed(digits).replaceFirst('.0', '');
        return {'count': compact, 'scale': unit.suffix};
      }
    }
    return {'count': count.toString()};
  }
}
