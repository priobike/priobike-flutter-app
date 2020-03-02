import 'package:bikenow/models/api/api_instruction.dart';
import 'package:bikenow/models/api/api_sg.dart';

class ApiRoute {
  String status;
  double distance;
  int time;
  int ascend;
  int descend;
  List<ApiInstruction> instructions;
  List<ApiSg> sg;

  ApiRoute({
    this.status,
    this.distance,
    this.time,
    this.ascend,
    this.descend,
    this.instructions,
    this.sg,
  });

  ApiRoute.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    distance = json['distance'];
    time = json['time'];
    ascend = json['ascend'];
    descend = json['descend'];
    if (json['route'] != null) {
      instructions = new List<ApiInstruction>();
      json['route'].forEach((v) {
        instructions.add(new ApiInstruction.fromJson(v));
      });
    }
    if (json['sg'] != null) {
      sg = new List<ApiSg>();
      json['sg'].forEach((v) {
        sg.add(new ApiSg.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['distance'] = this.distance;
    data['time'] = this.time;
    data['ascend'] = this.ascend;
    data['descend'] = this.descend;
    if (this.instructions != null) {
      data['route'] = this.instructions.map((v) => v.toJson()).toList();
    }
    if (this.sg != null) {
      data['sg'] = this.sg.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
