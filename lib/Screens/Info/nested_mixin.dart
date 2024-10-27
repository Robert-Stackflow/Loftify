import 'package:flutter/cupertino.dart';

abstract class StatefulWidgetForNested extends StatefulWidget {
  final bool nested;

  const StatefulWidgetForNested({super.key, required this.nested});
}
