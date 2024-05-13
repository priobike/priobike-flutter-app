import 'package:priobike/logging/logger.dart';
import 'package:priobike/routing/messages/graphhopper.dart';

class InstructionPreprocessing {
  static const INSTRUCTION_MIN_DISTANCE = 25;
  static final log = Logger("intruction-preprocessing");


  static List<GHInstruction> preprocess(GHRouteResponsePath path) {
    // return _extendShortInstructions(_removeWaypoints(path));
    return _removeWaypoints(path);
  }

  static List<GHInstruction> _extendShortInstructions(List<GHInstruction> instructions) {
    var mappedInstructions = List<GHInstruction>.empty(growable: true);
    for (final instruction in instructions) {
      if(mappedInstructions.isNotEmpty) {
        final lastInstruction = mappedInstructions.last;
        if(instruction.distance < INSTRUCTION_MIN_DISTANCE && lastInstruction.interval[0] < lastInstruction.interval[1] - 1) {
          mappedInstructions.last.interval[1] -= 1;
          var instr = GHInstruction.fromJson(instruction.toJson());
          instr.interval[0] -= 1;
          mappedInstructions.add(instr);
        }else{
          var instr = GHInstruction.fromJson(instruction.toJson());
          mappedInstructions.add(instr);
        }
      }else{
        var instr = GHInstruction.fromJson(instruction.toJson());
        mappedInstructions.add(instr);
      }
    }
    return mappedInstructions;

  }

  static List<GHInstruction> _removeWaypoints(GHRouteResponsePath path) {
    var mappedInstructions = List<GHInstruction>.empty(growable: true);
    var skipNext = false;
    for (final (index, instruction) in path.instructions.indexed) {
      if (skipNext) {
        skipNext = false;
        continue;
      }
      if(instruction.interval[0] == instruction.interval[1] && index + 1 < path.instructions.length) {
        final nextInstruction = path.instructions[index+1];
        if (nextInstruction.sign == 0) {
          var instructionJson = mappedInstructions.last.toJson();
          instructionJson["distance"] = instructionJson["distance"] + nextInstruction.distance;
          log.i("Instructioninterval ${instructionJson["interval"]}");
          instructionJson["interval"][1] = nextInstruction.interval[1];
          log.i("Instructioninterval ${instructionJson}");
          var instr = GHInstruction.fromJson(instructionJson);
          log.i(instr);
          mappedInstructions.last = instr;
          mappedInstructions.last.interval[1] = nextInstruction.interval[1];
          skipNext = true;
        }
      }else{
        var instr = GHInstruction.fromJson(instruction.toJson());
        mappedInstructions.add(instr);
      }
    }
    return mappedInstructions;
  }

  static void debugInstruction(List<GHInstruction> instructions) {
    log.i("-------------------------------\nDebug instructions:");
    instructions.forEach((element) {
      log.i("Instruction: ${element.interval[0]} - ${element.interval[1]} = ${element.distance} ---- ${element.text}");
    });
    log.i("-------------------------------");
  }
}