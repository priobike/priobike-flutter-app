import 'package:flutter/material.dart';

import 'dart:math';
class CrossingController{
  double lowerLimit;
  double upperLimit;

  double accuracyModifier;
  int crossQuantity;
  double maxAllowedAccuracy = 30;
  double lastAccuracy;
  List<double> distances = [];

  CrossingController(this.lowerLimit, this.upperLimit, this.accuracyModifier, this.crossQuantity);

  bool run(double distance, double accuracy){
    add(distance, accuracy);
    return isCrossed();

  }

  void add( double distance, double accuracy){
    if (distances.isNotEmpty){
      var lastDistance = distances.last;
      if (isInRange(distance) && accuracy < maxAllowedAccuracy && isAccurateEnough(distance, lastDistance, accuracy)){
        if (lastDistance > distance) {
          distances = [distance];
        } else {
          distances.add(distance);
        }
        lastAccuracy = accuracy;
      }
    }else{
      distances.add(distance);
      lastAccuracy = accuracy;
    }

  }

  bool isAccurateEnough(double distance, double lastDistance, double accuracy){
    var diff = (lastDistance - distance).abs();
    var acc = [(((lastAccuracy + accuracy) / 2) * accuracyModifier),0].reduce(max);

    if (diff < acc){
      return false;
    }

    return true;

  }

  bool isInRange(double distance){
    if (distance > lowerLimit && distance < upperLimit){
      return true;
    }
    return false;

  }

  bool isCrossed(){

    var isAscending = isSorted<double>(distances, (a,b) => a.compareTo(b));
    var crossCount = distances.length;

    if (isAscending && crossCount >= crossQuantity){
      return true;
    }
    return false;

  }

  bool isSorted<T>(List<T> list, [int Function(T, T) compare]) {
    if (list.length < 2) return true;
    compare ??= (T a, T b) => (a as Comparable<T>).compareTo(b);
    T prev = list.first;
    for (var i = 1; i < list.length; i++) {
      T next = list[i];
      if (compare(prev, next) > 0) return false;
      prev = next;
    }
    return true;
  }



}

