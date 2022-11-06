import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhisicsEngine {
  //DEFINITIONS
  //safety constants
  static const double speedCap = 50;
  static const double safeDistance = 0.35;
  static const double collisionStoppingFactor = 1.05;

  //phisics timer
  Timer? phisicsTimer;

  //keyboard
  RawKeyboard keyboard = RawKeyboard.instance;

  //simulation rate TODO variable sim rate with a minimum of 144 a second
  int simulationRate = 144;

  //player coordinates, speed, size in meters
  double x = 0;
  double y = 0;
  double speedX = 0;
  double speedY = 0;
  double w = 0;
  double h = 0;

  //forces: list of accelerations, with application time in ticks; -1 for unlimited time
  ForceList forces = ForceList();

  //friction: friction simply opposes to movement in any direction

  //fluid friction, proportional to the square of the speed
  double fluidFriction = 0;

  //walk acceleration and jump acceleration
  double walkAcceleration = 0;
  double jumpAcceleration = 0;

  //objects: things that collide with the player
  List<GameObject> gameObjects = [];

  //BASIC EXTENSIONS

  PhisicsEngine() {
    if (phisicsTimer?.isActive ?? true) {
      phisicsTimer?.cancel();
    }
    phisicsTimer = Timer.periodic(
      Duration(microseconds: 1e6 ~/ simulationRate),
      _doTick,
    );
  }

  void dispose() {
    phisicsTimer?.cancel();
  }

  //TODO implement logic :)

  //reset function
  void goTo([
    double x = 0,
    double y = 0,
  ]) {
    forces = ForceList();
    this.x = x;
    this.y = y;
    speedX = 0;
    speedY = 0;
  }

  //function run every tick
  void _doTick(var _) {
    //walk/slide speed modifier
    double xSpeedModifier = 1, ySpeedModifier = 1;
    int walkDirection = 0;
    //speed caps
    double speedCapX = speedCap;
    double speedCapY = speedCap;
    if (keyboard.keysPressed.contains(LogicalKeyboardKey.arrowLeft) &&
        !keyboard.keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      walkDirection = 1;
    }
    if (!keyboard.keysPressed.contains(LogicalKeyboardKey.arrowLeft) &&
        keyboard.keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      walkDirection = -1;
    }
    //collision detection
    double topOfPlayer = y + h / 2;
    double bottomOfPlayer = y - h / 2;
    double leftOfPlayer = x - w / 2;
    double rightOfPlayer = x + w / 2;
    for (GameObject obj in gameObjects) {
      double topOfObject = obj.y + obj.h / 2;
      double bottomOfObject = obj.y - obj.h / 2;
      double rightOfObject = -obj.x - obj.w / 2;
      double leftOfObject = -obj.x + obj.w / 2;

      //if player is in or touching a GameObject snap the player and apply a normal force
      if (topOfObject >= bottomOfPlayer &&
          topOfPlayer >= bottomOfObject &&
          rightOfPlayer >= rightOfObject &&
          leftOfObject >= leftOfPlayer) {
        //on top of object
        if (topOfObject <= bottomOfPlayer + safeDistance) {
          xSpeedModifier *= obj.xSpeedModifier;

          //apply normal force
          forces.forcesY["normal"] =
              Force(accelerationValue: -forces.getY, durationInTicks: 1);

          if (speedY <= 0) {
            y = topOfObject + h / 2;
            speedY /= collisionStoppingFactor;
          }
          //apply friction
          if (forces.forcesY["normal"]!.accelerationValue *
                      speedX.abs() *
                      xSpeedModifier >=
                  0 &&
              walkDirection * speedX * xSpeedModifier <= 0) {
            double temp = speedX.sign;
            speedX -= 2 *
                forces.forcesY["normal"]!.accelerationValue *
                obj.topFriction *
                speedX.sign /
                simulationRate;
            if (temp * speedX.sign == -1) speedX = 0;
          }
          //jump if up key is pressed
          if (keyboard.keysPressed.contains(LogicalKeyboardKey.arrowUp) &&
              obj.jumpable) {
            speedY = 0;
            y += 0.01;
            forces.forcesY["jump"] = Force(
                accelerationValue: jumpAcceleration,
                durationInTicks: simulationRate ~/ 8);
          }
          if (keyboard.keysPressed.contains(LogicalKeyboardKey.arrowDown) &&
              obj.passthrough) {
            if (speedY > -5) speedY = -5;
            y -= safeDistance;
          }
        } else
        //top collision
        if (topOfPlayer <= bottomOfObject + safeDistance && !obj.passthrough) {
          speedY /= collisionStoppingFactor;
          y = bottomOfObject - h / 2;
        } else
        //right collision
        if (rightOfPlayer >= leftOfObject + safeDistance && !obj.passthrough) {
          if (speedX < 0) speedX /= collisionStoppingFactor;
          x = leftOfObject + w / 2;
          speedCapY = obj.sideSpeedCap;
          if (keyboard.keysPressed.contains(LogicalKeyboardKey.arrowUp) &&
              obj.sideJumpable) {
            forces.forcesY["jump"] = Force(
                accelerationValue: jumpAcceleration / 1.412,
                durationInTicks: simulationRate ~/ 8);
            forces.forcesX["jump"] = Force(
                accelerationValue: jumpAcceleration / 1.412,
                durationInTicks: simulationRate ~/ 8);
          }
        } else
        //left collision
        if (rightOfObject >= leftOfPlayer - safeDistance && !obj.passthrough) {
          if (speedX > 0) speedX /= collisionStoppingFactor;
          x = rightOfObject - w / 2;
          speedCapY = obj.sideSpeedCap;
          if (keyboard.keysPressed.contains(LogicalKeyboardKey.arrowUp) &&
              obj.sideJumpable) {
            forces.forcesY["jump"] = Force(
                accelerationValue: jumpAcceleration / 1.412,
                durationInTicks: simulationRate ~/ 8);
            forces.forcesX["jump"] = Force(
                accelerationValue: -jumpAcceleration / 1.412,
                durationInTicks: simulationRate ~/ 8);
          }
        }
      }
    }
    //walking
    forces.forcesX["walk"] = Force(
        accelerationValue: walkDirection *
            (2 * walkAcceleration.abs() * xSpeedModifier - speedX.abs()),
        durationInTicks: 1);

    //apply forces
    speedX += 2 * forces.getX * xSpeedModifier / simulationRate;
    speedY += 2 * forces.getY * ySpeedModifier / simulationRate;
    //apply fluid friction
    double temp = speedX.sign;
    speedX -= fluidFriction * speedX * speedX * temp;
    if (temp * speedX.sign == -1) speedX = 0;
    temp = speedY.sign;
    speedY -= fluidFriction * speedY * speedY * temp;
    if (temp * speedY.sign == -1) speedY = 0;

    //speed cap to avoid glitches
    if (speedX.abs() > speedCapX) speedX = speedCapX * speedX.sign;
    if (speedY.abs() > speedCapY) speedY = speedCapY * speedY.sign;

    //apply speed
    x += speedX / simulationRate;
    y += speedY / simulationRate;
    //remove forces done applying
    forces.trim();
  }
}

class GameObject {
  double x, y, w, h, topFriction, sideSpeedCap, xSpeedModifier, ySpeedModifier;
  bool passthrough, jumpable, sideJumpable;
  Color color;
  GameObject({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.topFriction,
    required this.xSpeedModifier,
    required this.ySpeedModifier,
    this.sideSpeedCap = PhisicsEngine.speedCap,
    this.color = Colors.black,
    this.passthrough = false,
    this.jumpable = true,
    this.sideJumpable = true,
  });
}

class Force {
  double accelerationValue;
  int durationInTicks;
  Force({
    this.accelerationValue = 0,
    this.durationInTicks = 0,
  });

  @override
  String toString() {
    return "($accelerationValue for $durationInTicks ticks)";
  }
}

//if performance is an issue, convert map to list.
class ForceList {
  Map<String, Force> forcesX = {};
  Map<String, Force> forcesY = {};

  void trim() {
    List<String> list = forcesX.keys.toList();
    for (String i in list) {
      if (forcesX[i]!.durationInTicks > 0) forcesX[i]!.durationInTicks--;
      if (forcesX[i]!.durationInTicks == 0) forcesX.remove(i);
    }
    list = forcesY.keys.toList();
    for (String i in list) {
      if (forcesY[i]!.durationInTicks > 0) forcesY[i]!.durationInTicks--;
      if (forcesY[i]!.durationInTicks == 0) forcesY.remove(i);
    }
  }

  double get getX {
    double sum = 0;
    for (Force f in forcesX.values) {
      sum += f.accelerationValue;
    }
    return sum;
  }

  double get getY {
    double sum = 0;
    for (Force f in forcesY.values) {
      sum += f.accelerationValue;
    }
    return sum;
  }

  @override
  String toString() {
    return "x forces: $forcesX\ny forces: $forcesY";
  }
}
