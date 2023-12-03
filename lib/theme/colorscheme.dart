import 'package:flutter/material.dart';

final libraDarkColorScheme = ColorScheme.fromSeed(seedColor: Colors.lightBlue);

/// Chooses the label text color based on the background color
/// https://stackoverflow.com/questions/3942878/how-to-decide-font-color-in-white-or-black-depending-on-background-color
Color adaptiveTextColor(Color bkg) {
  if (bkg.alpha == 0) return Colors.black;
  if (bkg.red * 0.299 + bkg.green * 0.587 + bkg.blue * 0.114 > 186) return Colors.black;
  return Colors.white;
}


// ColorScheme(
//   brightness: Brightness.dark, 
//   primary: primary, 
//   onPrimary: onPrimary, 
//   secondary: secondary, 
//   onSecondary: onSecondary, 
//   error: error, 
//   onError: onError, 
//   background: background, 
//   onBackground: onBackground, 
//   surface: surface, 
//   onSurface: onSurface,
// )