import 'dart:math';

class HumanReadableDoubleStep {
  final int intStep;
  final int order;
  double get step => intStep * pow(10, order).toDouble();

  const HumanReadableDoubleStep({
    required this.intStep,
    required this.order,
  });

  HumanReadableDoubleStep nextLargerStep() {
    switch (intStep) {
      case 1:
        return HumanReadableDoubleStep(intStep: 2, order: order);
      case 2:
        return HumanReadableDoubleStep(intStep: 5, order: order);
      case 5:
        return HumanReadableDoubleStep(intStep: 1, order: order + 1);
      default:
        throw StateError("HumanReadableDoubleStep unkown intStep: $intStep");
    }
  }
}

HumanReadableDoubleStep _roundToHumanReadable(double targetStepSize, int order) {
  if (targetStepSize < 0.75) {
    return _roundToHumanReadable(targetStepSize * 10, order - 1);
  } else if (targetStepSize < 1.5) {
    return HumanReadableDoubleStep(intStep: 1, order: order);
  } else if (targetStepSize < 3) {
    return HumanReadableDoubleStep(intStep: 2, order: order);
  } else if (targetStepSize < 7.6) {
    // slight excess over 7.5 to ensure no infinite loop
    return HumanReadableDoubleStep(intStep: 5, order: order);
  } else {
    return _roundToHumanReadable(targetStepSize / 10, order + 1);
  }
}

HumanReadableDoubleStep roundToHumanReadable(double targetStepSize) {
  return _roundToHumanReadable(targetStepSize, 0);
}
