import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:salenight/logic.dart';

class ContainrrElement {
  String? name;
  Color? color;
  Size size;
  int variant;
  int firstAnimationFrame;
  int lastAnimationFrame;
  Duration animationDuration;
  Offset offset;
  bool centered;
  ImageRepeat repeat;
  Widget? overlay;

  ContainrrElement({
    this.name,
    // The base name of the element: if the asset is named assets/images/image-06@02.png the base name is assets/images/image
    // Asset names are to be created using this naming scheme: <BASENAME>+[-VARIANTNUMBER]+[@FRAMENUMBER]+<.EXTENSION>
    // Leave empty to only add the overlay and/or color
    this.color,
    // The object's background color, shown below the asset.
    this.overlay,
    // Standard widget nested in a SizedBox with the same size and position as the element
    required this.size,
    // Element size in pixels (or hundredths of the smallest screen size if the relativeSize is set to true in the Containrr)
    this.variant = 0,
    // The element variant: if the asset is named assets/images/image-06@02.png the variant is 6
    this.firstAnimationFrame = -1,
    // First animation frame to be played; must be lower or equal to lastAnimationFrame and lower than the total number of frames
    // -1 means the animation is played from the beginning
    this.lastAnimationFrame = -1,
    // Last animation frame to be played; must be greater or equal to firstAnimationFrame and lower than the total number of frames
    // -1 means the animation is played until the end
    this.animationDuration = const Duration(seconds: 1),
    // The time in which all frames in interval [firstAnimationFrame,lastAnimationFrame] are played
    this.offset = const Offset(0, 0),
    // Element offset in pixels (or hundredths of the smallest screen size if the relativeSize is set to true in the Containrr)
    // The offset is calculated from the top-left of the screen if centered is not set to tru
    this.centered = false,
    // Makes x and y coordinates relative to the center: x=0, y=0 means the element is centered
    this.repeat = ImageRepeat.noRepeat,
    // Sets the repetition for the painter
  });
}

class Containrr extends StatefulWidget {
  final Size size;
  //The size of the renderer
  final PhisicsEngine simulation;
  //The list of elements to be rendered
  final List<String> assetFolders;
  //Asset folders must also be declared in pubspec.yaml
  //Supported file extensions are .png, .jpeg, and .jpg
  final int refreshRate;
  final bool relativeSize;

  const Containrr({
    Key? key,
    required this.size,
    required this.simulation,
    this.assetFolders = const [],
    this.refreshRate = 30,
    this.relativeSize = false,
  }) : super(key: key);

  @override
  State<Containrr> createState() => _ContainrrState();
}

class _ContainrrState extends State<Containrr> {
  bool assetsLoaded = false;
  Map<String, Map<int, Map<int, ui.Image>>> assets = {};
  int currentLoadingIndex = 0;
  int itemNumber = 1;
  Timer? refreshTimer;
  double refreshTime = 0;
  List<ContainrrElement> elements = [];

  @override
  void initState() {
    _loadAssets();
    super.initState();
    if (refreshTimer != null) refreshTimer!.cancel();
    refreshTimer = Timer.periodic(
        Duration(microseconds: 1e6 ~/ widget.refreshRate), (timer) {
      refreshTime += 1 / widget.refreshRate;
      if (refreshTime > 60 * 60 * 24) refreshTime = 0;
      int i = 0;
      elements = [];
      while (i < widget.simulation.gameObjects.length &&
          widget.simulation.gameObjects[i].zIndex <= 0) {
        elements.add(widget.simulation.getRenderingElement(i++));
      }
      elements.add(
        ContainrrElement(
          size: Size(widget.simulation.w * widget.simulation.scale,
              widget.simulation.h * widget.simulation.scale),
          offset: Offset(
            widget.simulation.scale * widget.simulation.speedX * 0.01,
            widget.simulation.scale * widget.simulation.speedY * 0.01,
          ),
          centered: true,
          color: Colors.red,
        ),
      );
      while (i < widget.simulation.gameObjects.length) {
        elements.add(widget.simulation.getRenderingElement(i++));
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    if (refreshTimer != null) refreshTimer!.cancel();
    super.dispose();
  }

  Future _loadAssets() async {
    Map<String, dynamic> assetList =
        jsonDecode(await rootBundle.loadString('AssetManifest.json'));
    itemNumber = assetList.length;

    for (String path in assetList.keys) {
      bool assetHasExtension = path.contains(".");
      String extension = "";
      if (assetHasExtension) extension = path.split(".").last;
      if (extension == "png" || extension == "jpg" || extension == "jpeg") {
        String assetPath = "${(path.split("/")..removeLast()).join("/")}/";
        if (widget.assetFolders.contains(assetPath)) {
          String name = path.split("/").removeLast();
          bool assetHasFrameNumber = name.contains("@");
          int frameNumber = 0;
          bool assetHasVariant = name.contains("-");
          int variantNumber = 0;
          if (assetHasFrameNumber) {
            frameNumber = int.tryParse(
                  path.split("@").last.split("-").first.split(".").first,
                ) ??
                0;
          }
          if (assetHasVariant) {
            variantNumber = int.tryParse(
                  path.split("-").last.split("@").first.split(".").first,
                ) ??
                0;
          }
          name = name.split(".").first.split("@").first.split("-").first;
          if (assets["$assetPath$name"] == null) {
            assets["$assetPath$name"] = {};
          }
          if (assets["$assetPath$name"]![variantNumber] == null) {
            assets["$assetPath$name"]![variantNumber] = {};
          }
          assets["$assetPath$name"]![variantNumber]![frameNumber] =
              await decodeImageFromList(
                  (await rootBundle.load(path)).buffer.asUint8List());
          if (kDebugMode) {
            print(
                "_loadAssets - added:$path as assets[$assetPath$name][$variantNumber][$frameNumber]");
          }
        }
      }
      currentLoadingIndex++;
    }
    assetsLoaded = true;
  }

  ui.Image? getAsset(String? name, [int variant = 0, int frame = 0]) {
    if (name == null) return null;
    return assets[name]?[variant]?[frame];
  }

  int getLastFrame(String? name, [int variant = 0]) {
    if (name == null) return 0;
    return assets[name]?[variant]?.keys.last ?? 0;
  }

  int getFirstFrame(String? name, [int variant = 0]) {
    if (name == null) return 0;
    return assets[name]?[variant]?.keys.first ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    double relativeValue = 1;
    if (widget.relativeSize) {
      relativeValue = widget.size.shortestSide / 100;
    }
    List<Widget> overlays = [];
    for (ContainrrElement element in elements) {
      if (element.overlay != null) {
        double centerValueX = 0;
        double centerValueY = 0;
        if (element.centered) {
          centerValueX =
              widget.size.width / 2 - element.size.width * relativeValue / 2;
          centerValueY =
              widget.size.height / 2 - element.size.height * relativeValue / 2;
        }
        overlays.add(
          Positioned(
            top: element.offset.dy * relativeValue + centerValueY,
            left: element.offset.dx * relativeValue + centerValueX,
            child: SizedBox(
              width: element.size.width * relativeValue,
              height: element.size.height * relativeValue,
              child: element.overlay,
            ),
          ),
        );
      }
    }
    if (widget.assetFolders.isEmpty || elements.isEmpty) {
      return SizedBox(
        width: widget.size.width,
        height: widget.size.height,
        child: const Center(
          child: Text("Nothing to render"),
        ),
      );
    }
    if (!assetsLoaded) {
      return SizedBox(
        width: widget.size.width,
        height: widget.size.height,
        child: Center(
          child: LinearProgressIndicator(
            value: currentLoadingIndex / itemNumber,
          ),
        ),
      );
    }
    return SizedBox(
      width: widget.size.width,
      height: widget.size.height,
      child: CustomPaint(
        size: widget.size,
        painter: Painter(elements, getAsset, getLastFrame, getFirstFrame,
            widget.relativeSize, refreshTime),
        child: Stack(children: overlays),
      ),
    );
  }
}

class Painter extends CustomPainter {
  final List<ContainrrElement> elements;
  final Function getAsset;
  final Function getLastFrame;
  final Function getFirstFrame;
  final bool relativeSize;
  final double refreshTime;

  Painter(
    this.elements,
    this.getAsset,
    this.getLastFrame,
    this.getFirstFrame,
    this.relativeSize,
    this.refreshTime,
  );

  @override
  void paint(Canvas canvas, Size size) {
    for (ContainrrElement element in elements) {
      double relativeValue = 1;
      if (relativeSize) {
        relativeValue = size.shortestSide / 100;
      }

      double centerValueX = 0;
      double centerValueY = 0;
      if (element.centered) {
        centerValueX = size.width / 2 - element.size.width * relativeValue / 2;
        centerValueY =
            size.height / 2 - element.size.height * relativeValue / 2;
      }

      if (element.firstAnimationFrame == -1) {
        element.firstAnimationFrame =
            getFirstFrame(element.name, element.variant);
      }

      if (element.lastAnimationFrame == -1) {
        element.lastAnimationFrame =
            getLastFrame(element.name, element.variant);
      }
      int frameNumber =
          1 + element.lastAnimationFrame - element.firstAnimationFrame;
      int frameTimeInMicroseconds =
          element.animationDuration.inMicroseconds ~/ frameNumber;
      if (element.color != null) {
        canvas.drawRect(
          Rect.fromLTWH(
            element.offset.dx * relativeValue + centerValueX,
            element.offset.dy * relativeValue + centerValueY,
            element.size.width * relativeValue,
            element.size.height * relativeValue,
          ),
          Paint()..color = element.color!,
        );
      }
      ui.Image? image = getAsset(
          element.name,
          element.variant,
          ((refreshTime * 1000000).toInt() ~/ frameTimeInMicroseconds) %
                  frameNumber +
              element.firstAnimationFrame);
      if (image != null) {
        paintImage(
          canvas: canvas,
          rect: Rect.fromLTWH(
            element.offset.dx * relativeValue + centerValueX,
            element.offset.dy * relativeValue + centerValueY,
            element.size.width * relativeValue,
            element.size.height * relativeValue,
          ),
          image: image,
          fit: BoxFit.contain,
          repeat: element.repeat,
          scale: 1e-100,
          alignment: element.centered ? Alignment.center : Alignment.topLeft,
          flipHorizontally: false,
          filterQuality: FilterQuality.none,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
