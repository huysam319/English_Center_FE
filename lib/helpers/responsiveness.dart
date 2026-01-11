import 'package:flutter/material.dart';

const int largeScreenSize = 1366;
const int mediumScreenSize = 768;
const int smallScreenSize = 360;
const int customScreenSize = 1100;

class ResponsiveWidget extends StatelessWidget {
  final Widget largeScreen;
  // final Widget mediumScreen;
  final Widget smallScreen;
  // final Widget customScreen;

  const ResponsiveWidget({
    super.key, 
    required this.largeScreen, 
    // required this.mediumScreen, 
    // required this.customScreen, 
    required this.smallScreen,
  });

  static bool isSmallScreen(BuildContext context) => 
  MediaQuery.of(context).size.width < mediumScreenSize;

  static bool isMediumScreen(BuildContext context) => 
  MediaQuery.of(context).size.width >= mediumScreenSize &&
  MediaQuery.of(context).size.width < largeScreenSize;

  static bool islargeScreen(BuildContext context) => 
  MediaQuery.of(context).size.width >= largeScreenSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double _width = constraints.maxWidth;
        if (_width >= largeScreenSize) {
          return largeScreen;
        }
        else if (_width < largeScreenSize && _width >= mediumScreenSize) {
          return largeScreen;
        }
        else {
          return smallScreen;
        }
      },
    );
  }
}