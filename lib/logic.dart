import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GameObject {
  double x,
      y,
      w,
      h,
      topFriction,
      sideSpeedCap,
      xSpeedModifier,
      ySpeedModifier,
      bounceFactor,
      fluidFriction;
  bool passthrough,
      fluid,
      jumpable,
      sideJumpable,
      deadly,
      shop,
      checkpoint,
      visited = false;
  Color color;
  String texture;
  Force forceX, forceY;
  GameObject({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.topFriction = 0,
    this.fluidFriction = 0,
    this.xSpeedModifier = 1,
    this.ySpeedModifier = 1,
    this.bounceFactor = 0,
    this.forceX = const Force(accelerationValue: 0, durationInTicks: 0),
    this.forceY = const Force(accelerationValue: 0, durationInTicks: 0),
    this.sideSpeedCap = PhisicsEngine.speedCap,
    this.color = Colors.black,
    this.texture = "",
    this.passthrough = false,
    this.jumpable = true,
    this.sideJumpable = true,
    this.deadly = false,
    this.shop = false,
    this.checkpoint = false,
    this.fluid = false,
  });
  GameObject get copy {
    return GameObject(
      x: x,
      y: y,
      w: w,
      h: h,
      topFriction: topFriction,
      fluidFriction: fluidFriction,
      xSpeedModifier: xSpeedModifier,
      ySpeedModifier: ySpeedModifier,
      bounceFactor: bounceFactor,
      sideSpeedCap: sideSpeedCap,
      color: color,
      texture: texture,
      passthrough: passthrough,
      jumpable: jumpable,
      sideJumpable: sideJumpable,
      deadly: deadly,
      shop: shop,
      checkpoint: checkpoint,
      fluid: fluid,
      forceX: forceX.copy,
      forceY: forceY.copy,
    );
  }
}

class Force {
  final double accelerationValue;
  final int durationInTicks;
  const Force({
    this.accelerationValue = 0,
    this.durationInTicks = 0,
  });

  get copy => Force(
      accelerationValue: accelerationValue, durationInTicks: durationInTicks);

  @override
  String toString() {
    return "($accelerationValue for $durationInTicks ticks)";
  }
}

//if performance is an issue, convert map to list.
class ForceList {
  Map<String, Force> x;
  Map<String, Force> y;

  ForceList({
    required this.x,
    required this.y,
  });

  void trim() {
    List<String> list = x.keys.toList();
    for (String i in list) {
      if (x[i]!.durationInTicks > 0) {
        x[i] = Force(
            accelerationValue: x[i]!.accelerationValue,
            durationInTicks: x[i]!.durationInTicks - 1);
      }
      if (x[i]!.durationInTicks == 0) x.remove(i);
    }
    list = y.keys.toList();
    for (String i in list) {
      if (y[i]!.durationInTicks > 0) {
        y[i] = Force(
            accelerationValue: y[i]!.accelerationValue,
            durationInTicks: y[i]!.durationInTicks - 1);
      }
      if (y[i]!.durationInTicks == 0) y.remove(i);
    }
  }

  double get getX {
    double sum = 0;
    for (Force f in x.values) {
      sum += f.accelerationValue;
    }
    return sum;
  }

  double get getY {
    double sum = 0;
    for (Force f in y.values) {
      sum += f.accelerationValue;
    }
    return sum;
  }

  @override
  String toString() {
    return "x forces: $x\ny forces: $y";
  }
}

class PhisicsEngine {
  //DEFINITIONS

  //game end callback
  void Function() onGameOver;

  //safety constants
  static const double speedCap = 50;
  static const double safeDistance = 0.35;
  static const double collisionStoppingFactor = 1.05;

  //phisics timer
  Timer? phisicsTimer;

  //keyboard
  RawKeyboard? keyboard;

  //simulation rate TODO variable sim rate with a minimum of 144 a second
  int simulationRate = 144;

  //player coordinates, checkpoint, speed, size in meters
  double x = 0;
  double y = 0;
  double spawnX;
  double spawnY;
  double speedX = 0;
  double speedY = 0;
  double w;
  double h;

  //forces: list of accelerations, with application time in ticks; -1 for unlimited time
  ForceList forces = ForceList(x: {}, y: {});
  ForceList spawnForces;

  //friction: friction simply opposes to movement in any direction

  //fluid friction, proportional to the square of the speed
  double fluidFriction;

  //walk acceleration and jump acceleration
  double walkAcceleration;
  double jumpAcceleration;

  //objects: things that collide with the player
  List<GameObject> gameObjects;

  //BASIC EXTENSIONS

  PhisicsEngine({
    required this.w,
    required this.h,
    required this.walkAcceleration,
    required this.jumpAcceleration,
    required this.spawnForces,
    required this.onGameOver,
    this.spawnX = 0,
    this.spawnY = 0,
    this.fluidFriction = 0,
    this.gameObjects = const [],
  }) {
    forces = spawnForces;
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

  //respawn function
  void respawn() {
    forces = spawnForces;
    x = spawnX;
    y = spawnY;
    speedX = 0;
    speedY = 0;
  }

  //function run every tick
  void _doTick(var _) {
    //walk/slide speed modifier
    double speedModifierX = 1, speedModifierY = 1;

    //set walk direction: -1, 0 or 1
    int walkDirection = 0;
    if (keyboard != null &&
        keyboard!.keysPressed.contains(LogicalKeyboardKey.arrowLeft) &&
        !keyboard!.keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      walkDirection = 1;
    }
    if (keyboard != null &&
        !keyboard!.keysPressed.contains(LogicalKeyboardKey.arrowLeft) &&
        keyboard!.keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      walkDirection = -1;
    }

    //the comment at this location was removed for exceeding the maximum uselesness allowed
    double speedCapX = speedCap;
    double speedCapY = speedCap;

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
        //checkpoint handling
        if (obj.checkpoint) {
          if (!obj.visited) {
            spawnX = -obj.x;
            spawnY = obj.y;
          }
          obj.visited = true;
          continue;
        }

        //flag handling
        if (obj.shop) {
          obj.visited = true;
          bool allShopsVisited() {
            for (GameObject obj in gameObjects) {
              if (obj.shop && !obj.visited) return false;
            }
            return true;
          }

          if (allShopsVisited()) onGameOver();
          continue;
        }

        //deadly object handling
        if (obj.deadly) {
          respawn();
          obj.visited = true;
          break;
        }

        obj.visited = true;
        //on top of object
        if (topOfObject < bottomOfPlayer + safeDistance) {
          speedModifierX *= obj.xSpeedModifier;

          //go through the object if down key is pressed
          if (keyboard != null &&
              keyboard!.keysPressed.contains(LogicalKeyboardKey.arrowDown) &&
              obj.passthrough) {
            y -= safeDistance;
            continue;
          }

          //apply normal force
          forces.y["normal"] =
              Force(accelerationValue: -forces.getY, durationInTicks: 1);

          if (speedY <= 0) {
            y = topOfObject + h / 2;
            if (speedY <= -2 * safeDistance) {
              speedY *= -obj.bounceFactor;
            } else {
              speedY /= collisionStoppingFactor;
            }
          }
          //apply friction
          if (forces.y["normal"]!.accelerationValue *
                      speedX.abs() *
                      speedModifierX >=
                  0 &&
              walkDirection * speedX * speedModifierX <= 0) {
            double temp = speedX.sign;
            speedX -= 2 *
                forces.y["normal"]!.accelerationValue *
                obj.topFriction *
                speedX.sign /
                simulationRate;
            if (temp * speedX.sign == -1) speedX = 0;
          }
          //jump if up key is pressed
          if (keyboard != null &&
              keyboard!.keysPressed.contains(LogicalKeyboardKey.arrowUp) &&
              obj.jumpable) {
            speedY = 0;
            y += 0.01;
            _jumpUp();
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
          if (keyboard != null &&
              keyboard!.keysPressed.contains(LogicalKeyboardKey.arrowUp) &&
              obj.sideJumpable) {
            _jumpLeft();
          }
        } else
        //left collision
        if (rightOfObject >= leftOfPlayer - safeDistance && !obj.passthrough) {
          if (speedX > 0) speedX /= collisionStoppingFactor;
          x = rightOfObject - w / 2;
          speedCapY = obj.sideSpeedCap;
          if (keyboard != null &&
              keyboard!.keysPressed.contains(LogicalKeyboardKey.arrowUp) &&
              obj.sideJumpable) {
            _jumpRight();
          }
        }
      }
    }
    //walking
    walk(walkDirection, speedModifierX);

    //if jump key no longer held, remove accelerations
    if (keyboard != null &&
        !keyboard!.keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      forces.x.remove("jump");
      forces.y.remove("jump");
    }

    //apply forces and friction to the speeds, cap them
    //then apply the speeds to coordinates
    coordinateCalculation(speedModifierX, speedModifierY, speedCapX, speedCapY);

    //remove forces done applying
    forces.trim();
  }

  void coordinateCalculation(double speedModifierX, double speedModifierY,
      double speedCapX, double speedCapY) {
    //apply forces
    speedX += 2 * forces.getX * speedModifierX / simulationRate;
    speedY += 2 * forces.getY * speedModifierY / simulationRate;
    //apply dynamic friction
    double temp = speedX.sign;
    speedX -= fluidFriction * speedX * speedX * temp;
    if (temp * speedX.sign == -1) speedX = 0;
    temp = speedY.sign;
    speedY -= fluidFriction * speedY * speedY * temp;
    if (temp * speedY.sign == -1) speedY = 0;
    //apply speed caps
    if (speedX.abs() > speedCapX) speedX = speedCapX * speedX.sign;
    if (speedY.abs() > speedCapY) speedY = speedCapY * speedY.sign;
    //change coordinates
    x += speedX / simulationRate;
    y += speedY / simulationRate;
  }

  void walk(int walkDirection, double speedModifierX) {
    forces.x["walk"] = Force(
        accelerationValue: walkDirection *
            (2 * walkAcceleration.abs() * speedModifierX - speedX.abs()),
        durationInTicks: 1);
  } //basic player interactions

  void _jumpUp() {
    forces.y["jump"] = Force(
        accelerationValue: jumpAcceleration,
        durationInTicks: simulationRate ~/ 8);
  }

  void _jumpRight() {
    forces.y["jump"] = Force(
        accelerationValue: jumpAcceleration / 1.412,
        durationInTicks: simulationRate ~/ 8);
    forces.x["jump"] = Force(
        accelerationValue: -jumpAcceleration / 1.412,
        durationInTicks: simulationRate ~/ 8);
  }

  void _jumpLeft() {
    forces.y["jump"] = Force(
        accelerationValue: jumpAcceleration / 1.412,
        durationInTicks: simulationRate ~/ 8);
    forces.x["jump"] = Force(
        accelerationValue: jumpAcceleration / 1.412,
        durationInTicks: simulationRate ~/ 8);
  }
}
