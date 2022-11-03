class PlayerPos {
  //coordinates (x[0] and y[0]) along with their changes in time
  List<double> x = List.filled(5, 0);
  List<double> y = List.filled(5, 0);
  //friction: friction simply opposes to movement in any direction

  //proportional to the square of x[1]
  double dynamicFrictionX = 0;
  //proportional to the square of Y[1]
  double dynamicFrictionY = 0;
  //as the name implies
  double staticFrictionX = 0;
  double staticFrictionY = 0;

  void update() {
    //update everything down to speed
    for (int i = 3; i > 0; i--) {
      x[i] += x[i + 1] * (i + 1) / 200;
      y[i] += y[i + 1] * (i + 1) / 200;
    }

    //set the top unit of x change(eg acceleration), except speed and current position
    for (int i = 4; i > 1; i--) {
      if (x[i] != 0) {
        x[i] = 0;
        break;
      }
    }

    //set the top unit of y, except speed and current position
    for (int i = 4; i > 1; i--) {
      if (y[i] != 0) {
        y[i] = 0;
        break;
      }
    }

    //apply friction to speed
    double xSign = x[1].sign, ySign = y[1].sign;
    x[1] -= xSign * staticFrictionX / 200;
    y[1] -= ySign * staticFrictionY / 200;
    x[1] -= xSign * x[1] * x[1] * dynamicFrictionX / 200;
    y[1] -= ySign * y[1] * y[1] * dynamicFrictionY / 200;

    //if speed is overreduced by friction, set to 0
    if (x[1] * xSign < 1) x[1] = 0;
    if (y[1] * ySign < 1) y[1] = 0;

    //apply speed to coordinates
    x[0] += x[1] / 200;
    y[0] += y[1] / 200;
  }

  @override
  String toString() {
    return "x:$x\ny:$y\n"
        "xDynamicFriction: $dynamicFrictionX\nyDynamicFriction: $dynamicFrictionY\n"
        "yStaticFriction: $dynamicFrictionY\nyStaticFriction: $dynamicFrictionY";
  }
}
