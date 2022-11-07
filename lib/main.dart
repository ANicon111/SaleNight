import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:salenight/definitions.dart';
import 'package:salenight/logic.dart';
import 'package:salenight/stages.dart';

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
  int framesPerSecond = 60;
  Timer? refreshTimer;
  bool gameOver = false;
  bool levelSelect = true;

  void handleGameOver() {
    gameOver = true;
    simulation.keyboard = null;
    setState(() {});
  }

  void goToLevelSelect() {
    gameOver = false;
    levelSelect = true;
    setState(() {});
  }

  late PhisicsEngine simulation;
  List<String> stageSelector = ["Debug"];
  int currentStage = 0;

  void loadStage(Stage stage) {
    levelSelect = false;
    setState(() {});
    simulation
      ..w = stage.w
      ..h = stage.h
      ..spawnX = stage.spawnX
      ..spawnY = stage.spawnY
      ..walkAcceleration = stage.walkAcceleration
      ..jumpAcceleration = stage.jumpAcceleration
      ..fluidFriction = stage.fluidFriction
      ..spawnForces = stage.spawnForces
      ..gameObjects = stage.gameObjects.toList()
      ..keyboard = RawKeyboard.instance;
    simulation.respawn();
  }

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
    simulation = PhisicsEngine(
      onGameOver: handleGameOver,
      w: 0,
      h: 0,
      walkAcceleration: 0,
      jumpAcceleration: 0,
      fluidFriction: 0,
      spawnForces: ForceList(x: {}, y: {}),
    );
    loadStage(stages["default"]!);
    levelSelect = true;
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
    return Stack(
      children: [
        CustomPaint(
          foregroundPainter: Painter(simulation),
          size: MediaQuery.of(context).size,
        ),
        gameOver
            ? Center(
                child: Container(
                  width: 1000 * RelSize(context).pixel,
                  height: 1000 * RelSize(context).pixel,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(200),
                    borderRadius:
                        BorderRadius.circular(10 * RelSize(context).pixel),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding:
                            EdgeInsets.only(top: 120 * RelSize(context).pixel),
                        child: Text(
                          "Level Complete",
                          style: TextStyle(
                              fontSize: 80 * RelSize(context).pixel,
                              color: Colors.white),
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: EdgeInsets.all(
                          100 * RelSize(context).pixel,
                        ),
                        child: Container(
                          height: 100 * RelSize(context).pixel,
                          width: 400 * RelSize(context).pixel,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.shade400,
                            borderRadius: BorderRadius.circular(
                              10 * RelSize(context).pixel,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              goToLevelSelect();
                            },
                            hoverColor: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(
                              10 * RelSize(context).pixel,
                            ),
                            child: Center(
                              child: Text(
                                "Level Selector",
                                style: TextStyle(
                                  fontSize: 60 * RelSize(context).pixel,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : levelSelect
                ? Center(
                    child: Container(
                      width: 1000 * RelSize(context).pixel,
                      height: 1000 * RelSize(context).pixel,
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(200),
                        borderRadius:
                            BorderRadius.circular(10 * RelSize(context).pixel),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                                top: 60 * RelSize(context).pixel,
                                bottom: 60 * RelSize(context).pixel),
                            child: Text(
                              "Levels",
                              style: TextStyle(
                                  fontSize: 80 * RelSize(context).pixel,
                                  color: Colors.white),
                            ),
                          ),
                          SizedBox(
                            width: 800 * RelSize(context).pixel,
                            height: 750 * RelSize(context).pixel,
                            child: ListView.builder(
                              itemBuilder: (_, i) {
                                return Container(
                                  height: 100 * RelSize(context).pixel,
                                  width: 800 * RelSize(context).pixel,
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.shade400,
                                    borderRadius: BorderRadius.circular(
                                      10 * RelSize(context).pixel,
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      loadStage(stages[stageSelector[i]]!);
                                    },
                                    hoverColor: Colors.blueAccent,
                                    borderRadius: BorderRadius.circular(
                                      10 * RelSize(context).pixel,
                                    ),
                                    child: Center(
                                      child: Text(
                                        stageSelector[i],
                                        style: TextStyle(
                                          fontSize: 60 * RelSize(context).pixel,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              itemCount: stageSelector.length,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Positioned(
                    bottom: 10,
                    right: 10,
                    child: FloatingActionButton(
                      onPressed: () {
                        simulation.respawn();
                      },
                      child: const Icon(Icons.restart_alt),
                    ),
                  )
      ],
    );
  }
}

class Painter extends CustomPainter {
  PhisicsEngine simulation;
  Painter(this.simulation);

  @override
  void paint(Canvas canvas, Size size) {
    double u = size.shortestSide / 1000;

    //draw objects
    for (GameObject obj in simulation.gameObjects) {
      if (obj.shop) {
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset(
                size.width / 2 +
                    64 * (obj.x + simulation.x - simulation.speedX * 0.02) * u,
                size.height / 2 -
                    64 * (obj.y - simulation.y - simulation.speedY * 0.02) * u,
              ),
              width: 64 * obj.w * u,
              height: 64 * obj.h * u),
          Paint()..color = obj.visited ? Colors.amber : Colors.teal,
        );
      } else if (obj.checkpoint) {
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset(
                size.width / 2 +
                    64 * (obj.x + simulation.x - simulation.speedX * 0.02) * u,
                size.height / 2 -
                    64 * (obj.y - simulation.y - simulation.speedY * 0.02) * u,
              ),
              width: 64 * obj.w * u,
              height: 64 * obj.h * u),
          Paint()..color = obj.visited ? Colors.red : Colors.red.shade300,
        );
      } else {
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset(
                size.width / 2 +
                    64 * (obj.x + simulation.x - simulation.speedX * 0.02) * u,
                size.height / 2 -
                    64 * (obj.y - simulation.y - simulation.speedY * 0.02) * u,
              ),
              width: 64 * obj.w * u,
              height: 64 * obj.h * u),
          Paint()..color = obj.color,
        );
      }
    }

    //draw player
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(size.width / 2 - 64 * simulation.speedX * 0.02 * u,
              size.height / 2 + 64 * simulation.speedY * 0.02 * u),
          width: 64 * u * simulation.w,
          height: 64 * u * simulation.h),
      Paint()..color = Colors.red,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
