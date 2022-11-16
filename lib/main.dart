import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:salenight/definitions.dart';
import 'package:salenight/logic.dart';
import 'package:salenight/rendering.dart';
import 'package:salenight/stages.dart';

Map<String, ui.Image?> textures = {};
void main() {
  runApp(const GameRoot());
}

class GameRoot extends StatelessWidget {
  const GameRoot({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const Scaffold(
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
      ..gameObjects = ((stage.copy.gameObjects)
            ..sort(((a, b) => a.zIndex - b.zIndex)))
          .toList()
      ..keyboard = RawKeyboard.instance;
    simulation.respawn();
    setState(() {});
  }

  @override
  void initState() {
    if (refreshTimer?.isActive ?? true) {
      refreshTimer?.cancel();
    }
    simulation = PhisicsEngine(
      onGameOver: handleGameOver,
      w: 0,
      h: 0,
      walkAcceleration: 0,
      jumpAcceleration: 0,
      fluidFriction: 0,
      spawnForces: ForceList(x: {}, y: {}),
    );
    loadStage(stages["default"]!.copy);
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
        Containrr(
          size: MediaQuery.of(context).size,
          assetFolders: const ["textures/"],
          simulation: simulation,
          relativeSize: true,
          refreshRate: framesPerSecond,
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
                                      loadStage(stages[stageSelector[i]]!.copy);
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
