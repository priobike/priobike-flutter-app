// used for the dection of the screen edge when dragging a waypoint
import 'package:flutter/widgets.dart';

enum ScreenEdge {
  left,
  right,
  top,
  bottom,
  topright,
  topleft,
  bottomright,
  bottomleft,
  none,
}

// Check if the user dragged a waypoint to the edge of the screen
ScreenEdge getDragScreenEdge({required double x, required double y, required BuildContext context}) {
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;

  // the area of the screen that is considered the edge of the screen
  // the bottom area needs to be bigger because of the bottom sheet
  final minEdgeHeight = screenHeight * 0.15;
  final maxEdgeHeight = screenHeight * 0.75;
  final minEdgeWidth = screenWidth * 0.15;
  final maxEdgeWidth = screenWidth * 0.85;

  if (x <= minEdgeWidth && y <= minEdgeHeight) return ScreenEdge.topleft;
  if (x >= maxEdgeWidth && y <= minEdgeHeight) return ScreenEdge.topright;
  if (x <= minEdgeWidth && y >= maxEdgeHeight) return ScreenEdge.bottomleft;
  if (x >= maxEdgeWidth && y >= maxEdgeHeight) return ScreenEdge.bottomright;

  if (x <= minEdgeWidth) return ScreenEdge.left;
  if (x >= maxEdgeWidth) return ScreenEdge.right;
  if (y <= minEdgeHeight) return ScreenEdge.top;
  if (y >= maxEdgeHeight) return ScreenEdge.bottom;

  return ScreenEdge.none;
}

// Calculates how the map should move when dragging a waypoint to the edge of the screen
Map<String, double> moveCameraWhenDraggingToScreenEdge({required ScreenEdge screenEdge}) {
  // determines how fast the map moves when dragging a waypoint to the edge of the screen
  const moveSpeed = 15.0;
  final double moveCameraX;
  final double moveCameraY;
  switch (screenEdge) {
    case ScreenEdge.bottom:
      moveCameraX = 0.0;
      moveCameraY = -moveSpeed;
      break;
    case ScreenEdge.top:
      moveCameraX = 0.0;
      moveCameraY = moveSpeed;
      break;
    case ScreenEdge.right:
      moveCameraX = -moveSpeed;
      moveCameraY = 0.0;
      break;
    case ScreenEdge.left:
      moveCameraX = moveSpeed;
      moveCameraY = 0.0;
      break;
    case ScreenEdge.topleft:
      moveCameraX = moveSpeed;
      moveCameraY = moveSpeed;
      break;
    case ScreenEdge.topright:
      moveCameraX = -moveSpeed;
      moveCameraY = moveSpeed;
      break;
    case ScreenEdge.bottomleft:
      moveCameraX = moveSpeed;
      moveCameraY = -moveSpeed;
      break;
    case ScreenEdge.bottomright:
      moveCameraX = -moveSpeed;
      moveCameraY = -moveSpeed;
      break;

    default:
      moveCameraX = 0.0;
      moveCameraY = 0.0;
      break;
  }
  final map = {'x': moveCameraX, 'y': moveCameraY};
  return map;
}
