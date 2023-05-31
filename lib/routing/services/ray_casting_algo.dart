/// This file was taken from: https://github.com/molteo-engineering-team/point_in_polygon
/// It is used to check if the coordinates are inside the bounding box of the city
/// by checking if a point is inside a polygon.
/// 
/// MIT License
/// 
/// Copyright (c) 2021 Molteo
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in all
/// copies or substantial portions of the Software.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
/// SOFTWARE.

class Point {
  Point({required this.x, required this.y});

  /// X axis coordinate or longitude
  double x;

  /// Y axis coordinate or latitude
  double y;
}

class Poly {
  /// Check if a Point [point] is inside a polygon representing by a List of Point [vertices]
  /// by using a Ray-Casting algorithm
  static bool isPointInPolygon(Point point, List<Point> vertices) {
    int intersectCount = 0;
    for (int i = 0; i < vertices.length; i += 1) {
      final Point vertB = i == vertices.length - 1 ? vertices[0] : vertices[i + 1];
      if (Poly.rayCastIntersect(point, vertices[i], vertB)) {
        intersectCount += 1;
      }
    }
    return (intersectCount % 2) == 1;
  }

  /// Ray-Casting algorithm implementation
  /// Calculate whether a horizontal ray cast eastward from [point]
  /// will intersect with the line between [vertA] and [vertB]
  /// Refer to `https://en.wikipedia.org/wiki/Point_in_polygon` for more explanation
  /// or the example comment bloc at the end of this file
  static bool rayCastIntersect(Point point, Point vertA, Point vertB) {
    final double aY = vertA.y;
    final double bY = vertB.y;
    final double aX = vertA.x;
    final double bX = vertB.x;
    final double pY = point.y;
    final double pX = point.x;

    if ((aY > pY && bY > pY) || (aY < pY && bY < pY) || (aX < pX && bX < pX)) {
      // The case where the ray does not possibly pass through the polygon edge,
      // because both points A and B are above/below the line,
      // or both are to the left/west of the starting point
      // (as the line travels eastward into the polygon).
      // Therefore we should not perform the check and simply return false.
      // If we did not have this check we would get false positives.
      return false;
    }

    // y = mx + b : Standard linear equation
    // (y-b)/m = x : Formula to solve for x

    // M is rise over run -> the slope or angle between vertices A and B.
    final double m = (aY - bY) / (aX - bX);
    // B is the Y-intercept of the line between vertices A and B
    final double b = ((aX * -1) * m) + aY;
    // We want to find the X location at which a flat horizontal ray at Y height
    // of pY would intersect with the line between A and B.
    // So we use our rearranged Y = MX+B, but we use pY as our Y value
    final double x = (pY - b) / m;

    // If the value of X
    // (the x point at which the ray intersects the line created by points A and B)
    // is "ahead" of the point's X value, then the ray can be said to intersect with the polygon.
    return x > pX;
  }

/**
 * Ray-Casting algorithm: https://en.wikipedia.org/wiki/Point_in_polygon
 * 
 * Example case
 *
 * Let's  say we have a point and a polygon already, represented by this graph:
 *
 *   |
 *  5|
 *   |
 *   |
 *  4|                       * Vertice B (4, 4)
 *   |                      / \
 *   |                     /   \
 *  3|     * Point (1, 3) /     \
 *   |                   /       \
 *   |                  /         \
 *  2|                 /           \
 *   |                /             \
*    |               /               \
 *  1|             * Vertice A (2, 1) \
 *   |              \                  \
 *   |               \                  \
 * -----------------------------------------------------------
 *  0|     1     2     3     4     5     6     7     8     9
 *
 *
 * We will draw a horizontal line from Point and for each line between the vertices, 
 * we will figure out whether our horizontal line crosses that line. 
 * Then if the total number is even (or zero) after doing that calculation for all lines, 
 * we know the point is outside, if it is odd it's inside:
 *
 *  *
 *   |
 *  5|        * -----------------------------------------> 0 collisions, point is outside
 *   |
 *   |
 *  4|                       * Vertice B (4, 4)
 *   |                      / \
 *   |                     /   \
 *  3|     * -----------> /---->\----------> 2 collisions, even, point is outside
 *   |                   /       \
 *   |                  /         \
 *  2|                 /           \
 *   |                /    *------->\------> 1 collision, odd, point is inside
*    |               /               \
 *  1|             * Vertice A (2, 1) \
 *   |              \                  \
 *   |               \                  \
 * -----------------------------------------------------------
 *  0|     1     2     3     4     5     6     7     8     9
 *
 *
 * So if we don't have the lines, only the corners of the polygon how do we 
 * calculate the intersections?
 *
 * y = mx + b
 * In this standard linear equation, M is the slope of the line and B is the 
 * y-intercept of the line. So if we rearrange it to solve for an X value 
 * (as we want to find the X value at which our horizontal line from our point 
 * would touch the edge, and whether that value is > the real X), 
 * we can insert our point Y value as Y and get our result if we have M and B 
 * for the line between two vertices.
 *
 * In our example:
 *  *
 *   |
 *  5|
 *   |
 *   |
 *  4|                       * Vertice B (4, 4)
 *   |                      / \
 *   |                     /   \
 *  3|     * Point (1, 3) /     \
 *   |                   /       \
 *   |                  /         \
 *  2|                 /           \
 *   |                /             \
*    |               /               \
 *  1|             * Vertice A (2, 1) \
 *   |              \                  \
 *   |               \                  \
 * -----------------------------------------------------------
 *  0|     1     2     3     4     5     6     7     8     9
 *
 * M is 1.5:
 * m = (aY - bY) / (aX - bX)
 * m = ( 1 - 4 ) / ( 2 - 4 )
 * m = 1,5
 * 
 * B is -2:
 * b = ((aX * -1) * m) + aY
 * b = (( 2 * -1) * 1.5) + 1
 * b = -2
 * 
 * Therefore our intercept point is 3.33:
 * x = (pY - b) / m
 * x = (3 - -2) / 1.5
 * x = 3,33
 *
 * 3.33 is > our point's X val of 1, so this time the ray intercepts the line. 
 * We would do this calculation for all the other edges, 
 * and in our example we would have 2 intercepts, so Point is outside the polygon.
 */
}
