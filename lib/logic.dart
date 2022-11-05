import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhisicsEngine {
  //DEFINITIONS

  //phisics timer
  Timer? phisicsTimer;

  //keyboard
  RawKeyboard keyboard = RawKeyboard.instance;

  //simulation rate TODO variable sim rate
  int simulationRate = 200;

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

  //TODO implement logic
  void _doTick(var _) {
    double xSpeedModifier = 1, ySpeedModifier = 1;
    //walking
    if (keyboard.keysPressed.contains(LogicalKeyboardKey.arrowLeft) &&
        !keyboard.keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      forces.forcesX["walk"] = Force(
          accelerationValue: walkAcceleration / sqrt(speedX.abs() / 5 + .01),
          durationInTicks: 1);
    }
    if (keyboard.keysPressed.contains(LogicalKeyboardKey.arrowRight) &&
        !keyboard.keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      forces.forcesX["walk"] = Force(
          accelerationValue: -walkAcceleration / sqrt(speedX.abs() / 5 + .01),
          durationInTicks: 1);
    }
    //collision detection
    double topOfPlayer = y + h / 2;
    double bottomOfPlayer = y - h / 2;
    double leftOfPlayer = x - w / 2;
    double rightOfPlayer = x + w / 2;
    for (GameObject obj in gameObjects) {
      double topOfObject = obj.y + obj.h / 2;
      double bottomOfObject = obj.y - obj.h / 2;
      double leftOfObject = -obj.x - obj.w / 2;
      double rightOfObject = -obj.x + obj.w / 2;

      //if player is in or touching a GameObject snap the player and apply a normal force
      if (topOfObject >= bottomOfPlayer &&
          topOfPlayer >= bottomOfObject &&
          rightOfPlayer >= leftOfObject &&
          rightOfObject >= leftOfPlayer &&
          obj.passthrough == false) {
        //on top of object
        if (bottomOfPlayer > topOfObject - 0.2) {
          xSpeedModifier *= obj.xSpeedModifier;
          y = topOfObject + h / 2;
          if (speedY < 0) speedY = 0;
          //apply friction
          if (forces.getX * speedX <= 0) {
            double temp = speedX.sign;
            speedX += 2 *
                forces.getY *
                obj.topFriction *
                speedX.sign /
                simulationRate;
            if (temp * speedX.sign == -1) speedX = 0;
          }
          //jump if up key is pressed
          if (keyboard.keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
            speedY = 0;
            y += 0.01;
            forces.forcesY["jump"] =
                Force(accelerationValue: jumpAcceleration, durationInTicks: 25);
          }
        }
      }
    }
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
    //apply speed
    x += speedX * xSpeedModifier / simulationRate;
    y += speedY * ySpeedModifier / simulationRate;
    //remove forces done applying
    forces.trim();
  }
}

class GameObject {
  double x, y, w, h, topFriction, sideFriction, xSpeedModifier, ySpeedModifier;
  bool passthrough;
  Color color;
  GameObject({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.topFriction,
    required this.sideFriction,
    required this.xSpeedModifier,
    required this.ySpeedModifier,
    this.color = Colors.black,
    this.passthrough = false,
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
