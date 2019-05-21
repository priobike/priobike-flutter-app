import 'package:bike_now/models/phase.dart';

class LSAPrediction{
  int lsaId;
  List<SGPrediction> sgPredictions;

}
class SGPrediction{
  String sgName;
  List<Phase> phases;
}