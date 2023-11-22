import 'package:flutter/material.dart';

final libraTextTheme = Typography.blackMountainView.copyWith(
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
      fontSize: 18,
      fontWeight: FontWeight.w500,
    ),
    titleLarge: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500,
    ));

// Using google fonts might require internet?
// import 'package:google_fonts/google_fonts.dart';
// final libraTextTheme = Typography.blackMountainView.copyWith(
//   headlineSmall: GoogleFonts.robotoSlab(),
// );
