import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:salenight/logic.dart';

//TODO not broken keyboard detector

void main() {
  runApp(const GameRoot());
}

class GameRoot extends StatelessWidget {
  const GameRoot({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: GameRenderer(),
      ),
    );
  }
}

class GameRenderer extends StatefulWidget {
  const GameRenderer({Key? key}) : super(key: key);

  @override
  State<GameRenderer> createState() => _GameRendererState();
}

class _GameRendererState extends State<GameRenderer> {
  //TODO implement variable fps
  int framesPerSecond = 30;
  Timer? refreshTimer;

  //TODO actual level design lol
  PhisicsEngine simulation = PhisicsEngine()
    ..fluidFriction = 0.001
    ..gameObjects = [
      GameObject(0, 100, 1000, 10, 200, 300),
      GameObject(550, -100, 200, 10, 200, 300),
    ];

  int jumpTime = 0, movetime = 0;
  bool isJumping = false;

  @override
  void initState() {
    if (refreshTimer?.isActive ?? true) {
      refreshTimer?.cancel();
    }
    refreshTimer = Timer.periodic(
      Duration(microseconds: 1e6 ~/ framesPerSecond),
      (_) {
        setState(() {});
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    simulation.dispose();
    refreshTimer?.cancel();
    super.dispose();
  }

  FocusNode focusNode = FocusNode();
  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      autofocus: true,
      onKey: (value) {
        if (value.logicalKey == LogicalKeyboardKey.arrowUp) {
          if (!isJumping) jumpTime = 20;
        }
        if (value.logicalKey == LogicalKeyboardKey.arrowLeft) {
          movetime = 50;
        }
        if (value.logicalKey == LogicalKeyboardKey.arrowRight) {
          movetime = -50;
        }
      },
      focusNode: focusNode,
      child: CustomPaint(
        foregroundPainter: Painter(simulation),
        size: MediaQuery.of(context).size,
      ),
    );
  }
}

class Painter extends CustomPainter {
  PhisicsEngine simulation;
  Painter(this.simulation);

  @override
  void paint(Canvas canvas, Size size) {
    double u = size.shortestSide / 1000;

    //draw player
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(size.width / 2 + simulation.speedX * 0.01 * u,
              size.height / 2 + simulation.speedY * 0.01 * u),
          width: 100 * u,
          height: 150 * u),
      Paint()..color = Colors.red,
    );

    //draw objects
    for (GameObject obj in simulation.gameObjects) {
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset(
              size.width / 2 +
                  (obj.x + simulation.x + simulation.speedX * 0.01) * u,
              size.height / 2 +
                  (obj.y - simulation.y - simulation.speedY * 0.01) * u,
            ),
            width: obj.w * u,
            height: obj.h * u),
        Paint()..color = Colors.black,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
