import 'package:flutter/material.dart';
import 'package:salenight/logic.dart';

class Stage {
  List<GameObject> gameObjects;
  double walkAcceleration,
      jumpAcceleration,
      fluidFriction,
      w,
      h,
      spawnX,
      spawnY;
  ForceList spawnForces;
  Stage({
    required this.gameObjects,
    required this.spawnForces,
    this.walkAcceleration = 7.5,
    this.jumpAcceleration = 50,
    this.fluidFriction = 5e-5,
    this.w = 1.125,
    this.h = 1.75,
    this.spawnX = 0,
    this.spawnY = 0,
  });
  Stage get copy {
    Stage copy = this;
    copy.gameObjects =
        List.generate(gameObjects.length, (index) => gameObjects[index].copy);
    return copy;
  }
}

//TODO actual level design and textures
Map<String, Stage> stages = {
  "default": Stage(
    gameObjects: [
      GameObject(
        x: 0,
        y: 0,
        w: 10,
        h: 2,
        color: Colors.brown,
        texture: "textures/grass",
      ),
      GameObject(
        x: 0,
        y: -5,
        w: 50,
        h: 10,
        texture: "textures/water",
        animationDuration: const Duration(milliseconds: 500),
        deadly: true,
      ),
    ],
    spawnForces: ForceList(x: {}, y: {
      "gravity": const Force(accelerationValue: -9.81, durationInTicks: -1),
    }),
    spawnY: 1.875,
    fluidFriction: 0,
  ),
  "Debug": Stage(
      spawnForces: ForceList(
        x: {},
        y: {
          "gravity": const Force(accelerationValue: -9.81, durationInTicks: -1),
        },
      ),
      gameObjects: [
        GameObject(
          x: 0,
          y: -15,
          w: 200,
          h: 20,
          fluidFriction: 0.0025,
          texture: "textures/water",
          animationDuration: const Duration(milliseconds: 500),
          translucent: true,
          zIndex: 1,
          forceY: const Force(accelerationValue: 6, durationInTicks: 1),
        ),
        GameObject(
          x: -5,
          y: -2,
          w: 20,
          h: 0.1,
          friction: 3,
          speedModifierX: 1,
          speedModifierY: 1,
          color: Colors.black,
        ),
        GameObject(
          x: 0,
          y: 8,
          w: 1,
          h: 1,
          shop: true,
        ),
        GameObject(
          x: 5,
          y: 6,
          w: 1,
          h: 1,
          checkpoint: true,
        ),
        GameObject(
          x: 5,
          y: -5,
          w: 20,
          h: 0.1,
          friction: 0.1,
          speedModifierX: 1,
          speedModifierY: 1,
          color: Colors.lightBlue,
        ),
        GameObject(
          x: 5,
          y: 1,
          w: 20,
          h: 0.1,
          friction: 3,
          speedModifierX: 0.5,
          color: Colors.green,
          bounceFactor: 0.8,
        ),
        GameObject(
          x: 5,
          y: 4,
          w: 5,
          h: 1,
          friction: 3,
          speedModifierX: 0,
          color: Colors.grey,
          passthrough: true,
          jumpable: false,
        ),
        GameObject(
          x: -12,
          y: -2,
          w: 0.1,
          h: 20,
          speedCapY: 1,
          color: Colors.black12,
        ),
        GameObject(
          x: 13,
          y: -2,
          w: 0.1,
          h: 20,
          friction: 3,
          speedCapY: 5,
          color: Colors.lightBlue.withAlpha(30),
          sideJumpable: false,
        ),
        GameObject(
          x: 0,
          y: -10,
          w: 1000,
          h: 0.01,
          friction: 3,
          color: Colors.red,
          deadly: true,
        ),
        GameObject(
          x: -6,
          y: 12,
          w: 10,
          h: 1,
          speedCapX: 1,
          forceX: const Force(
            accelerationValue: -1,
            durationInTicks: 1,
          ),
          color: Colors.purple,
          jumpable: false,
          walkable: false,
        ),
        GameObject(
          x: -12,
          y: 11,
          w: 1,
          h: 8,
          fluidFriction: .1,
          speedCapY: 1,
          forceY: const Force(
            accelerationValue: 100,
            durationInTicks: 1,
          ),
          color: Colors.purple,
          translucent: true,
          jumpable: false,
        ),
      ]),
};
