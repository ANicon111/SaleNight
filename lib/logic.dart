import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:salenight/rendering.dart';

class GameObject {
  double x,
      y,
      w,
      h,
      friction,
      speedCapX,
      speedCapY,
      speedModifierX,
      speedModifierY,
      bounceFactor,
      fluidFriction;
  bool passthrough,
      translucent,
      jumpable,
      sideJumpable,
      walkable,
      deadly,
      shop,
      checkpoint,
      visited = false;
  int zIndex, textureVariant;
  Color? color;
  Force forceX, forceY;
  String texture;
  Duration animationDuration;
  ImageRepeat repeat;
  GameObject({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.friction = 0,
    this.fluidFriction = 0,
    this.speedModifierX = 1,
    this.speedModifierY = 1,
    this.bounceFactor = 0,
    this.forceX = const Force(accelerationValue: 0, durationInTicks: 0),
    this.forceY = const Force(accelerationValue: 0, durationInTicks: 0),
    this.speedCapX = PhisicsEngine.speedCap,
    this.speedCapY = PhisicsEngine.speedCap,
    this.color,
    this.texture = "",
    this.passthrough = false,
    this.jumpable = true,
    this.sideJumpable = true,
    this.walkable = true,
    this.deadly = false,
    this.shop = false,
    this.checkpoint = false,
    this.translucent = false,
    this.zIndex = 0,
    this.textureVariant = 0,
    this.animationDuration = const Duration(seconds: 1),
    this.repeat = ImageRepeat.repeat,
  });
  GameObject get copy {
    return GameObject(
      x: x,
      y: y,
      w: w,
      h: h,
      friction: friction,
      fluidFriction: fluidFriction,
      speedModifierX: speedModifierX,
      speedModifierY: speedModifierY,
      bounceFactor: bounceFactor,
      speedCapX: speedCapX,
      speedCapY: speedCapY,
      color: color,
      texture: texture,
      passthrough: passthrough,
      jumpable: jumpable,
      sideJumpable: sideJumpable,
      walkable: walkable,
      deadly: deadly,
      shop: shop,
      checkpoint: checkpoint,
      translucent: translucent,
      forceX: forceX.copy,
      forceY: forceY.copy,
      zIndex: zIndex,
      textureVariant: textureVariant,
      animationDuration: animationDuration,
      repeat: repeat,
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

  //movement chacks

  bool get _right =>
      keyboard != null &&
      keyboard!.keysPressed.contains(LogicalKeyboardKey.arrowRight);

  bool get _left =>
      keyboard != null &&
      keyboard!.keysPressed.contains(LogicalKeyboardKey.arrowLeft);

  bool get _down =>
      keyboard != null &&
      keyboard!.keysPressed.contains(LogicalKeyboardKey.arrowDown);

  bool get _up =>
      keyboard != null &&
      keyboard!.keysPressed.contains(LogicalKeyboardKey.arrowUp);

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

  //fluid friction, proportional to the square of the speed
  double fluidFriction;

  //walk acceleration and jump acceleration
  double walkAcceleration;
  double jumpAcceleration;

  //jump cooldown
  int jumpCooldown = 0;
  int sideJumpCooldown = 0;

  //scale: rendering scale
  double scale = 5;

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

  //rendering element getter
  ContainrrElement getRenderingElement(int i) {
    GameObject obj = gameObjects[i];
    return ContainrrElement(
      size: Size(scale * obj.w, scale * obj.h),
      offset: Offset(scale * (obj.x + x - speedX * 0.01),
          -scale * (obj.y - y - speedY * 0.01)),
      color: obj.color,
      name: obj.texture,
      variant: obj.textureVariant,
      repeat: obj.repeat,
      animationDuration: obj.animationDuration,
      centered: true,
    );
  }

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
    double speedModifierX = 1,
        speedModifierY = 1,
        fluidFriction = this.fluidFriction;

    //set walk direction: -1, 0 or 1
    int walkDirection = 0;
    if (_left && !_right) {
      walkDirection = 1;
    }
    if (!_left && _right) {
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

        //visit object
        obj.visited = true;

        //flag handling
        if (obj.shop) {
          bool allShopsVisited() {
            for (GameObject obj in gameObjects) {
              if (obj.shop && !obj.visited) return false;
            }
            return true;
          }

          if (obj.visited && allShopsVisited()) onGameOver();
          continue;
        }

        //apply speed caps
        if (speedCapX > obj.speedCapX) {
          speedCapX = obj.speedCapX;
        }
        if (speedCapY > obj.speedCapY) {
          speedCapY = obj.speedCapY;
        }

        //apply object forces
        forces.x["translucent"] = obj.forceX;
        forces.y["translucent"] = obj.forceY;

        //translucent handling
        if (obj.translucent) {
          fluidFriction = obj.fluidFriction;

          if (obj.jumpable &&
              _up &&
              y < topOfObject - safeDistance &&
              y > bottomOfObject + safeDistance &&
              x < leftOfObject + safeDistance &&
              x > rightOfObject - safeDistance) {
            _jumpUp();
          }
          continue;
        }

        //deadly object handling
        if (obj.deadly) {
          respawn();
          break;
        }

        //bottom collision
        if (topOfObject < bottomOfPlayer + safeDistance) {
          //apply relevant speed modifier
          speedModifierX *= obj.speedModifierX;

          //stop walking if disabled
          if (!obj.walkable) walkDirection = 0;

          //go through the object if down key is pressed
          if (_down && obj.passthrough) {
            y -= safeDistance;
            continue;
          }

          //bounce / stop
          if (speedY <= 0) {
            y = topOfObject + h / 2;
            if (speedY <= -2 * safeDistance && !_down) {
              speedY *= -obj.bounceFactor;
            } else {
              speedY /= collisionStoppingFactor;
            }
          }

          //apply normal force
          forces.y["normal"] =
              Force(accelerationValue: -forces.getY, durationInTicks: 1);

          //apply surface friction
          if (forces.y["normal"]!.accelerationValue *
                      speedX.abs() *
                      speedModifierX >=
                  0 &&
              walkDirection * speedX * speedModifierX <= 0) {
            double temp = speedX.sign;
            speedX -= 2 *
                forces.y["normal"]!.accelerationValue *
                obj.friction *
                speedX.sign /
                simulationRate;
            if (temp * speedX.sign == -1) speedX = 0;
          }
          //jump if up key is pressed
          if (_up && obj.jumpable) {
            speedY = 0;
            _jumpUp();
          }
        } else
        //top collision
        if (topOfPlayer <= bottomOfObject + safeDistance && !obj.passthrough) {
          //apply relevant speed modifier
          speedModifierX *= obj.speedModifierX;

          //bounce / stop
          if (speedY >= 0) {
            y = bottomOfObject - h / 2;
            if (speedY >= 2 * safeDistance && !_down) {
              speedY *= -obj.bounceFactor;
            } else {
              speedY /= collisionStoppingFactor;
            }
          }

          y = bottomOfObject - h / 2;
        } else
        //right collision
        if (rightOfPlayer >= leftOfObject + safeDistance && !obj.passthrough) {
          //apply relevant speed modifier
          speedModifierY *= obj.speedModifierY;

          //bounce / stop
          if (speedX <= 0) {
            x = leftOfObject + w / 2;
            if (speedX <= -2 * safeDistance && !_right) {
              speedX *= -obj.bounceFactor;
            } else {
              speedX /= collisionStoppingFactor;
            }
          }

          x = leftOfObject + w / 2;
          if (_up && obj.sideJumpable) {
            _jumpLeft();
          }
        } else
        //left collision
        if (rightOfObject >= leftOfPlayer - safeDistance && !obj.passthrough) {
          //apply relevant speed modifier
          speedModifierY *= obj.speedModifierY;

          //bounce / stop
          if (speedX >= 0) {
            x = rightOfObject - w / 2;
            if (speedX >= 2 * safeDistance && !_left) {
              speedX *= -obj.bounceFactor;
            } else {
              speedX /= collisionStoppingFactor;
            }
          }

          x = rightOfObject - w / 2;
          if (_up && obj.sideJumpable) {
            _jumpRight();
          }
        }
      }
    }
    //walking
    walk(walkDirection, speedModifierX);

    //if jump key no longer held, remove accelerations
    if (!_up) {
      forces.x.remove("jump");
      forces.y.remove("jump");
    }

    //apply forces and friction to the speeds, cap them
    //then apply the speeds to coordinates
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

    //remove forces done applying
    forces.trim();

    //decrease cooldowns
    if (jumpCooldown > 0) jumpCooldown--;
    if (sideJumpCooldown > 0) sideJumpCooldown--;
  }

  void walk(int walkDirection, double speedModifierX) {
    forces.x["walk"] = Force(
        accelerationValue: walkDirection *
            (2 * walkAcceleration.abs() * speedModifierX - speedX.abs()),
        durationInTicks: 1);
  } //basic player interactions

  void _jumpUp() {
    if (jumpCooldown == 0) {
      forces.y["jump"] = Force(
          accelerationValue: jumpAcceleration,
          durationInTicks: simulationRate ~/ 8);
      jumpCooldown = simulationRate ~/ 2;
      speedY = 0;
    }
  }

  void _jumpRight() {
    if (sideJumpCooldown == 0) {
      forces.y["jump"] = Force(
          accelerationValue: jumpAcceleration / 1.412,
          durationInTicks: simulationRate ~/ 8);
      forces.x["jump"] = Force(
          accelerationValue: -jumpAcceleration / 1.412,
          durationInTicks: simulationRate ~/ 8);
      sideJumpCooldown = simulationRate ~/ 2;
      speedX = 0;
      speedY = 0;
    }
  }

  void _jumpLeft() {
    if (sideJumpCooldown == 0) {
      forces.y["jump"] = Force(
          accelerationValue: jumpAcceleration / 1.412,
          durationInTicks: simulationRate ~/ 8);
      forces.x["jump"] = Force(
          accelerationValue: jumpAcceleration / 1.412,
          durationInTicks: simulationRate ~/ 8);
      sideJumpCooldown = simulationRate ~/ 2;
      speedX = 0;
      speedY = 0;
    }
  }
}
