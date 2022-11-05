import 'dart:async';

import 'package:flutter/material.dart';
import 'package:salenight/logic.dart';

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
    ..fluidFriction = 0.00002
    ..w = 1
    ..h = 1.5
    ..walkAcceleration = 7.5
    ..jumpAcceleration = 50
    ..gameObjects = [
      GameObject(
        x: 0,
        y: -2,
        w: 20,
        h: 0.1,
        topFriction: 3,
        sideFriction: 300,
        xSpeedModifier: 1,
        ySpeedModifier: 1,
        color: Colors.black,
      ),
      GameObject(
        x: 5,
        y: -5,
        w: 20,
        h: 0.1,
        topFriction: 0.1,
        sideFriction: 300,
        xSpeedModifier: 1,
        ySpeedModifier: 1,
        color: Colors.lightBlue,
      ),
      GameObject(
        x: 5,
        y: 1,
        w: 20,
        h: 0.1,
        topFriction: 3,
        sideFriction: 300,
        xSpeedModifier: 0.5,
        ySpeedModifier: 1,
        color: Colors.green,
      ),
      GameObject(
        x: -12,
        y: -2,
        w: 0.1,
        h: 20,
        topFriction: 3,
        sideFriction: 300,
        xSpeedModifier: 1,
        ySpeedModifier: 1,
        color: Colors.black,
      ),
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
    simulation.forces.forcesY["gravity"] =
        Force(accelerationValue: -9.81, durationInTicks: -1);
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
    return CustomPaint(
      foregroundPainter: Painter(simulation),
      size: MediaQuery.of(context).size,
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
          center: Offset(size.width / 2 + 64 * simulation.speedX * 0.02 * u,
              size.height / 2 + 64 * simulation.speedY * 0.02 * u),
          width: 64 * u * simulation.w,
          height: 64 * u * simulation.h),
      Paint()..color = Colors.red,
    );

    //draw objects
    for (GameObject obj in simulation.gameObjects) {
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset(
              size.width / 2 +
                  64 * (obj.x + simulation.x + simulation.speedX * 0.02) * u,
              size.height / 2 -
                  64 * (obj.y - simulation.y + simulation.speedY * 0.02) * u,
            ),
            width: 64 * obj.w * u,
            height: 64 * obj.h * u),
        Paint()..color = obj.color,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
