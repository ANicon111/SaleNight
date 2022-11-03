import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Timer? phisicsTimer, refreshTimer;
  PlayerPos playerPos = PlayerPos()
    ..dynamicFrictionX = 0.01
    ..dynamicFrictionY = 0.01;

  void _doTick(var _) {
    print(playerPos);
    playerPos.y[2] = 0.01;
    playerPos.update();
  }

  @override
  void initState() {
    if (phisicsTimer?.isActive ?? true) {
      phisicsTimer?.cancel();
    }
    phisicsTimer = Timer.periodic(const Duration(milliseconds: 5), _doTick);
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
    phisicsTimer?.cancel();
    refreshTimer?.cancel();
    super.dispose();
  }

  FocusNode focusNode = FocusNode();
  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      autofocus: true,
      onKeyEvent: (value) {
        if (value.logicalKey == LogicalKeyboardKey.arrowUp) {
          playerPos.y[2] = -0.1;
        }
      },
      focusNode: focusNode,
      child: CustomPaint(
        foregroundPainter: Painter(playerPos),
        size: MediaQuery.of(context).size,
      ),
    );
  }
}

class Painter extends CustomPainter {
  PlayerPos pos;
  Painter(this.pos);

  @override
  void paint(Canvas canvas, Size size) {
    double u = size.shortestSide / 1000;

    //draw player
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(
              size.width / 2 + pos.x[1] * 10, size.height / 2 + pos.y[1] * 10),
          width: 100 * u,
          height: 50 * u),
      Paint()..color = Colors.black,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
