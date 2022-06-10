import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class SpeedometerGaugeRange extends GaugeRange {
  SpeedometerGaugeRange({
    Key? key, 
    required Gradient gradient ,
    required double minSpeed,
    required double maxSpeed,
  }) : super(key: key, 
    startValue: minSpeed,
    endValue: maxSpeed,
    sizeUnit: GaugeSizeUnit.factor,
    startWidth: 0.25,
    endWidth: 0.25,
    gradient: gradient,
  );
}

class SpeedometerNeedlePointer extends NeedlePointer {
  const SpeedometerNeedlePointer({Key? key, required double speedKmh}) : super(key: key, 
    value: speedKmh,
    needleLength: 0.875,
    enableAnimation: true,
    animationType: AnimationType.ease,
    needleStartWidth: 1,
    needleEndWidth: 8,
    needleColor: const Color.fromARGB(255, 44, 62, 80),
    knobStyle: const KnobStyle(knobRadius: 0.05, sizeUnit: GaugeSizeUnit.factor, color: Color.fromARGB(255, 44, 62, 80))
  );
}

class SpeedometerRadialGauge extends SfRadialGauge {
  SpeedometerRadialGauge({
    Key? key, 
    required List<Color> colors, 
    required List<double> stops,
    required double speedKmh,
    required double minSpeed,
    required double maxSpeed,
  }) : super(key: key, 
    axes: <RadialAxis>[
      RadialAxis(
        minimum: minSpeed, 
        maximum: maxSpeed, 
        startAngle: 165,
        endAngle: 15,
        interval: 5,
        minorTicksPerInterval: 4,
        showAxisLine: true,
        radiusFactor: 0.95,
        labelOffset: 15,
        axisLineStyle: const AxisLineStyle(thicknessUnit: GaugeSizeUnit.factor, thickness: 0.25),
        majorTickStyle: const MajorTickStyle(length: 10, thickness: 4, color: Color.fromARGB(255, 44, 62, 80)),
        minorTickStyle: const MinorTickStyle(length: 5, thickness: 1, color: Color.fromARGB(255, 52, 73, 94)),
        axisLabelStyle: const GaugeTextStyle(color: Color.fromARGB(255, 44, 62, 80), fontWeight: FontWeight.bold, fontSize: 14),
        ranges: [
          SpeedometerGaugeRange(
            minSpeed: minSpeed,
            maxSpeed: maxSpeed,
            gradient: SweepGradient(
              colors: colors,
              stops: stops,
            )
          )
        ],
        pointers: [
          SpeedometerNeedlePointer(
            speedKmh: speedKmh,
          ),
        ],
      ),
    ],
  );
}