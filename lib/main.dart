import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_shaders/flutter_shaders.dart';

import 'dart:ui' as ui;

void main() {
  runApp(const MyApp());
}

Future<ui.Image> getUiImage(
    String imageAssetPath, int height, int width) async {
  final ByteData assetImageByteData = await rootBundle.load(imageAssetPath);
  final codec = await ui.instantiateImageCodec(
    assetImageByteData.buffer.asUint8List(),
    targetHeight: height,
    targetWidth: width,
  );
  return (await codec.getNextFrame()).image;
}

final uvImage = getUiImage("uv.webp", 2730, 4096);
final app = GlobalKey(debugLabel: "app");

class MobileToggle extends ValueNotifier<bool> {
  MobileToggle() : super(false);

  void toggle() => value = !value;
}

final mobileToggle = MobileToggle();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: mobileToggle,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQueryData.fromView(View.of(context)).copyWith(
            devicePixelRatio: mobileToggle.value ? 4 : null,
            textScaler:
                mobileToggle.value ? const TextScaler.linear(1.5) : null,
          ),
          child: ColoredBox(
            color: Colors.white,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedOpacity(
                  opacity: mobileToggle.value ? 1 : 0,
                  duration: Durations.long1,
                  child: Image.asset("phone.webp"),
                ),
                AnimatedSwitcher(
                  duration: Durations.long2,
                  child: !mobileToggle.value
                      ? child!
                      : FutureBuilder(
                          future: uvImage,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return child!;
                            final uv = snapshot.requireData;
                            return ShaderBuilder(
                              assetKey: "cornerpin.frag",
                              (context, shader, child) {
                                return AnimatedSampler(
                                  (image, size, canvas) {
                                    shader.setFloat(0, size.width);
                                    shader.setFloat(1, size.height);
                                    shader.setImageSampler(0, image);
                                    shader.setImageSampler(1, uv);

                                    canvas.drawRect(
                                      Rect.fromLTWH(
                                          0, 0, size.width, size.height),
                                      Paint()..shader = shader,
                                    );
                                  },
                                  child: AspectRatio(
                                    aspectRatio: 240 / 400,
                                    child: child!,
                                  ),
                                );
                              },
                              child: child,
                            );
                          },
                        ),
                )
              ],
            ),
          ),
        );
      },
      child: MaterialApp(
        key: app,
        title: 'Responsive App',
        home: const MyHomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Set<ResponsiveStrategy> _selected = {ResponsiveStrategy.strategies.first};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Responsive App"),
        actions: [
          IconButton(
            onPressed: mobileToggle.toggle,
            tooltip: mobileToggle.value
                ? "Switch to desktop mode"
                : "Switch to mobile mode",
            icon: ListenableBuilder(
              listenable: mobileToggle,
              builder: (context, _) => AnimatedSwitcher(
                duration: Durations.short1,
                child: mobileToggle.value
                    ? const Icon(key: ValueKey(0), Icons.smartphone)
                    : const Icon(key: ValueKey(1), Icons.computer),
              ),
            ),
          )
        ],
      ),
      floatingActionButton: SegmentedButton(
        segments: [
          for (final strategy in ResponsiveStrategy.strategies)
            ButtonSegment(
              icon: strategy.icon,
              label: strategy.label,
              tooltip: strategy.tooltip,
              value: strategy,
            ),
        ],
        selected: _selected,
        onSelectionChanged: (selected) => setState(() => _selected = selected),
      ),
      body: _selected.single,
    );
  }
}

sealed class ResponsiveStrategy extends StatelessWidget {
  const ResponsiveStrategy({super.key});

  static const List<ResponsiveStrategy> strategies = [
    FixedContentSizeStrategy(),
    ScreenPercentageStrategy(),
    BreakpointStrategy(),
  ];

  Widget get icon;

  Widget get label;

  String? get tooltip;
}

class FixedContentSizeStrategy extends ResponsiveStrategy {
  const FixedContentSizeStrategy({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (var i = 0; i < 10; i++)
            Card(
              color: i % 2 == 0
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.tertiaryContainer,
              child: SizedBox(
                width: 128 * 2,
                height: 128,
                child: Center(
                  child: Text(
                    '$i',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget get icon => const Icon(Icons.wrap_text);

  @override
  Widget get label => const Text("Fixed Size");

  @override
  String? get tooltip => "Items have an intrinsic size";
}

class ScreenPercentageStrategy extends ResponsiveStrategy {
  const ScreenPercentageStrategy({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return ListView.builder(
          itemExtent: width / 3,
          itemBuilder: (context, index) {
            return Center(
              child: SizedBox(
                width: width * 2 / 3,
                child: Card(
                  color: index % 2 == 0
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.tertiaryContainer,
                  child: Center(
                    child: Text(
                      '$index',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget get icon => const Icon(Icons.percent);

  @override
  Widget get label => const Text("Percentage");

  @override
  String? get tooltip => "Scaling as a percentage of the screen size";
}

class BreakpointStrategy extends ResponsiveStrategy {
  const BreakpointStrategy({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 500 && constraints.maxHeight > 400) {
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              childAspectRatio: 2,
            ),
            itemBuilder: (context, index) {
              return Card(
                color: index % 2 == 0
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.tertiaryContainer,
                child: Center(
                  child: Text(
                    '$index',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              );
            },
          );
        } else {
          return ListView.builder(
            scrollDirection: constraints.maxWidth > constraints.maxHeight
                ? Axis.horizontal
                : Axis.vertical,
            itemExtent: 128,
            itemBuilder: (context, index) {
              return Center(
                child: SizedBox(
                  width: 300,
                  child: Card(
                    color: index % 2 == 0
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.tertiaryContainer,
                    child: Center(
                      child: Text(
                        '$index',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }

  @override
  Widget get icon => const Icon(Icons.account_tree);

  @override
  Widget get label => const Text("Breakpoint");

  @override
  String? get tooltip => "Adapting to screen width";
}
