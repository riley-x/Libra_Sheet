import 'dart:math';

(double, int) _roundToHumanReadable(double targetStepSize, int order) {
  if (targetStepSize < 0.75) {
    return _roundToHumanReadable(targetStepSize * 10, order - 1);
  } else if (targetStepSize < 1.5) {
    return (pow(10, order).toDouble(), order);
  } else if (targetStepSize < 3) {
    return (2 * pow(10, order).toDouble(), order);
  } else if (targetStepSize < 7.6) {
    // slight excess over 7.5 to ensure no infinite loop
    return (5 * pow(10, order).toDouble(), order);
  } else {
    return _roundToHumanReadable(targetStepSize / 10, order + 1);
  }
}

(double, int) roundToHumanReadable(double targetStepSize) {
  return _roundToHumanReadable(targetStepSize, 0);
}
