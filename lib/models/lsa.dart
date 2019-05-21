import 'package:bike_now/models/prediction.dart';
import 'package:bike_now/models/sg.dart';

import 'abstract_classes/locatable.dart';
import 'abstract_classes/crossable.dart';

class LSA with Crossable, Locatable{
  int id;
  String name;
  List<SG> sgs;
  List<SGPrediction> sgPredictions = new List<SGPrediction>();

  SG getSG(){

  }



  @override
  bool calculateIsCrossed(double distance, double accuracy) {
    // TODO: implement calculateIsCrossed
    return null;
  }

}