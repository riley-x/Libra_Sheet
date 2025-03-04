import 'package:flutter/material.dart';
import 'package:libra_sheet/theme/colorscheme.dart';

final libraTextTheme = Typography.blackMountainView.copyWith(
  displayLarge: const TextStyle(
    fontFamily: "RobotoSlab",
    fontSize: 26,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.75,
  ),
  displayMedium: const TextStyle(
    fontFamily: "RobotoSlab",
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  ),
  displaySmall: const TextStyle(
    fontFamily: "RobotoSlab",
    fontSize: 18,
    fontWeight: FontWeight.w500,
  ),
  headlineLarge: const TextStyle(
    fontFamily: "RobotoSlab",
    fontSize: 26,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.75,
  ),
  headlineMedium: const TextStyle(
    fontFamily: "RobotoSlab",
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  ),
  headlineSmall: const TextStyle(
    fontFamily: "RobotoSlab",
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.0,
  ),
  titleLarge: const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
  ),
  bodySmall: TextStyle(
    color: libraLightColorScheme.onBackground,
  ),
  labelSmall: const TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
  ),
);

final libraDarkTextTheme = Typography.whiteMountainView.copyWith(
  displayLarge: const TextStyle(
    fontFamily: "RobotoSlab",
    fontSize: 26,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.75,
  ),
  displayMedium: const TextStyle(
    fontFamily: "RobotoSlab",
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  ),
  displaySmall: const TextStyle(
    fontFamily: "RobotoSlab",
    fontSize: 18,
    fontWeight: FontWeight.w500,
  ),
  headlineLarge: const TextStyle(
    fontFamily: "RobotoSlab",
    fontSize: 26,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.75,
  ),
  headlineMedium: const TextStyle(
    fontFamily: "RobotoSlab",
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  ),
  headlineSmall: const TextStyle(
    fontFamily: "RobotoSlab",
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.0,
  ),
  titleLarge: const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
  ),
  bodySmall: TextStyle(
    color: libraDarkColorScheme.onBackground,
  ),
  labelSmall: const TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
  ),
);


// Using google fonts might require internet?
// import 'package:google_fonts/google_fonts.dart';
// final libraTextTheme = Typography.blackMountainView.copyWith(
//   headlineSmall: GoogleFonts.robotoSlab(),
// );
