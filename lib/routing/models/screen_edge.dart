// used for the dection of the screen edge when dragging a waypoint
import 'package:flutter/widgets.dart';

enum ScreenEdge {
  left,
  right,
  top,
  bottom,
  topRight,
  topLeft,
  bottomRight,
  bottomLeft,
  none,
}

// Check if the user dragged a waypoint to the edge of the screen
ScreenEdge getDragScreenEdge({required double x, required double y, required BuildContext context}) {
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;

  // the area of the screen that is considered the edge of the screen
  // the bottom area needs to be bigger because of the bottom sheet
  final minEdgeHeight = screenHeight * 0.17; // top
  final maxEdgeHeight = screenHeight * 0.70; // bottom
  final minEdgeWidth = screenWidth * 0.17; // left
  final maxEdgeWidth = screenWidth * 0.83; // right

  if (x <= minEdgeWidth && y <= minEdgeHeight) return ScreenEdge.topLeft;
  if (x >= maxEdgeWidth && y <= minEdgeHeight) return ScreenEdge.topRight;
  if (x <= minEdgeWidth && y >= maxEdgeHeight) return ScreenEdge.bottomLeft;
  if (x >= maxEdgeWidth && y >= maxEdgeHeight) return ScreenEdge.bottomRight;

  if (x <= minEdgeWidth) return ScreenEdge.left;
  if (x >= maxEdgeWidth) return ScreenEdge.right;
  if (y <= minEdgeHeight) return ScreenEdge.top;
  if (y >= maxEdgeHeight) return ScreenEdge.bottom;

  return ScreenEdge.none;
}

// Calculates how the map should move when dragging a waypoint to the edge of the screen
Map<String, double> moveCameraWhenDraggingToScreenEdge({required ScreenEdge screenEdge}) {
  // determines how fast the map moves when dragging a waypoint to the edge of the screen
  const mapMoveSpeed = 5.0;

  final double moveCameraX;
  final double moveCameraY;
  switch (screenEdge) {
    case ScreenEdge.bottom:
      moveCameraX = 0.0;
      moveCameraY = -mapMoveSpeed;
      break;
    case ScreenEdge.top:
      moveCameraX = 0.0;
      moveCameraY = mapMoveSpeed;
      break;
    case ScreenEdge.right:
      moveCameraX = -mapMoveSpeed;
      moveCameraY = 0.0;
      break;
    case ScreenEdge.left:
      moveCameraX = mapMoveSpeed;
      moveCameraY = 0.0;
      break;
    case ScreenEdge.topLeft:
      moveCameraX = mapMoveSpeed;
      moveCameraY = mapMoveSpeed;
      break;
    case ScreenEdge.topRight:
      moveCameraX = -mapMoveSpeed;
      moveCameraY = mapMoveSpeed;
      break;
    case ScreenEdge.bottomLeft:
      moveCameraX = mapMoveSpeed;
      moveCameraY = -mapMoveSpeed;
      break;
    case ScreenEdge.bottomRight:
      moveCameraX = -mapMoveSpeed;
      moveCameraY = -mapMoveSpeed;
      break;
    default:
      moveCameraX = 0.0;
      moveCameraY = 0.0;
      break;
  }
  return {'x': moveCameraX, 'y': moveCameraY};
}
