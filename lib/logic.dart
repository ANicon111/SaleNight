import 'dart:async';

class PhisicsEngine {
  //DEFINITIONS

  //phisics timer
  Timer? phisicsTimer;

  //simulation rate TODO variable sim rate
  int simulationRate = 200;

  //player coordinates, speed, size
  double x = 0;
  double y = 0;
  double speedX = 0;
  double speedY = 0;
  double w = 0;
  double h = 0;

  //forces: list of accelerations, with application time in ticks; -1 for unlimited time
  List<Force> forcesX = [];
  List<Force> forcesY = [];

  //friction: friction simply opposes to movement in any direction

  //fluid friction, proportional to the square of the speed
  double fluidFriction = 0;
  //static friction caused by touching a surface
  double staticFrictionX = 0;
  double staticFrictionY = 0;

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
    //print(this);

    //TEMP
    // ignore_for_file: unused_local_variable
    //TEMP

    bool onTopObject = false;
    bool onLeftObject = false;
    bool onRightObject = false;
    for (GameObject obj in gameObjects) {
      bool belowObject = obj.y + obj.h / 2 + h / 2 <= y;
      bool aboveObject = obj.y - obj.h / 2 - h / 2 >= y;
      bool leftOfObject = obj.x + obj.w / 2 + w / 2 <= x;
      bool rightOfObject = obj.x - obj.w / 2 - w / 2 >= x;
    }
    x = 0;
    y = 0;
    speedX = 0;
    speedY = 0;
  }
}

class GameObject {
  double x, y, w, h, topFriction, sideFriction;
  bool passthrough;
  GameObject(
    this.x,
    this.y,
    this.w,
    this.h,
    this.topFriction,
    this.sideFriction, {
    this.passthrough = false,
  });
}

class Force {
  String name;
  double accelerationValue;
  int durationInTicks;
  Force({
    this.name = "DEBUG",
    this.accelerationValue = 0,
    this.durationInTicks = 0,
  });
}
