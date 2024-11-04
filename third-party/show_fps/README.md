# Show FPS

[![GitHub stars](https://img.shields.io/github/stars/mantreshkhurana/show_fps.svg?style=social)](https://github.com/mantreshkhurana/show_fps)
[![pub package](https://img.shields.io/pub/v/show_fps.svg)](https://pub.dartlang.org/packages/show_fps)

Use ShowFPS to monitor your app's FPS (Frames Per Second) in real time.

![Screenshot](https://raw.githubusercontent.com/mantreshkhurana/show_fps/stable/screenshots/screenshot-1.png)

## Installation

Add `show_fps: ^1.0.6` in your project's pubspec.yaml:

```yaml
dependencies:
  show_fps: ^1.0.6
```

## Usage

Import `show_fps` in your dart file:

```dart
import 'package:show_fps/show_fps.dart';
```

Then warp your Main Widget with `ShowFPS` widget:

```dart
CupertinoApp(
      title: 'FPS Monitor',
      theme: CupertinoThemeData(
        brightness: Brightness.light,
      ),
      debugShowCheckedModeBanner: false,
      home: ShowFPS(
        alignment: Alignment.topRight,
        visible: true,
        showChart: false,
        borderRadius: BorderRadius.all(Radius.circular(11)),
        child: MyHomePage(title: 'FPS Monitor'),
      ),
    );
```
