import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as HTTP;
import 'package:priobike/config/config.dart';
import 'package:priobike/config/logger.dart';

import 'package:priobike/models/api/api_route.dart';
import 'package:priobike/models/recommendation.dart';
import 'package:priobike/models/route_request.dart';

abstract class Session {
  StreamController<ApiRoute> routeStreamController =
      new StreamController<ApiRoute>();

  StreamController<Recommendation> recommendationStreamController =
      new StreamController<Recommendation>();

  HTTP.Client httpClient = HTTP.Client();

  String sessionId;

  Logger log = Logger("Session");

  void updateRoute(
    double fromLat,
    double fromLon,
    double toLat,
    double toLon,
  ) {
    log.i(json.encode(RouteRequest(
      sessionId: sessionId,
      from: Position(lat: fromLat, lon: fromLon),
      to: Position(lat: toLat, lon: toLon),
    ).toJson()));
    httpClient
        .post(
            '${Config.SESSIONWRAPPER_HOST}:${Config.SESSIONWRAPPER_PORT}/getroute',
            body: json.encode(RouteRequest(
              sessionId: sessionId,
              from: Position(lat: fromLat, lon: fromLon),
              to: Position(lat: toLat, lon: toLon),
            ).toJson()))
        .then((HTTP.Response response) {
      log.i(response.body);
      routeStreamController.add(ApiRoute.fromJson(json.decode(response.body)));
    });

    // for debug purposes TODO: remove me later

    // Future.delayed(
    //     Duration(seconds: 1),
    //     () => routeStreamController.add(ApiRoute.fromJson(json.decode(
    //         '{"points":[{"lon":13.727212,"lat":51.030799,"ele":140},{"lon":13.727054,"lat":51.031433,"ele":138},{"lon":13.727161,"lat":51.031456,"ele":138},{"lon":13.727124,"lat":51.031659,"ele":134},{"lon":13.72702,"lat":51.031715,"ele":134},{"lon":13.727642,"lat":51.031921,"ele":134},{"lon":13.727692,"lat":51.031862,"ele":134},{"lon":13.729138,"lat":51.032362,"ele":133},{"lon":13.729619,"lat":51.032545,"ele":128},{"lon":13.729919,"lat":51.032626,"ele":128},{"lon":13.730212,"lat":51.032633,"ele":128},{"lon":13.730246,"lat":51.032741,"ele":128},{"lon":13.730335,"lat":51.032891,"ele":128},{"lon":13.73054,"lat":51.033155,"ele":128},{"lon":13.73089,"lat":51.033836,"ele":127},{"lon":13.731166,"lat":51.034212,"ele":120},{"lon":13.731939,"lat":51.035907,"ele":118},{"lon":13.733341,"lat":51.038836,"ele":118},{"lon":13.733482,"lat":51.039063,"ele":118},{"lon":13.734404,"lat":51.040165,"ele":116},{"lon":13.734586,"lat":51.040431,"ele":116},{"lon":13.734934,"lat":51.040869,"ele":112},{"lon":13.735274,"lat":51.041239,"ele":114},{"lon":13.735666,"lat":51.041612,"ele":114},{"lon":13.735868,"lat":51.041766,"ele":117},{"lon":13.736995,"lat":51.042877,"ele":117},{"lon":13.739406,"lat":51.044743,"ele":117},{"lon":13.739993,"lat":51.045175,"ele":115},{"lon":13.740298,"lat":51.045372,"ele":115},{"lon":13.741189,"lat":51.045853,"ele":115},{"lon":13.741988,"lat":51.046225,"ele":116},{"lon":13.742703,"lat":51.046511,"ele":116},{"lon":13.743293,"lat":51.046783,"ele":115},{"lon":13.743574,"lat":51.046953,"ele":115},{"lon":13.743844,"lat":51.047176,"ele":115},{"lon":13.74413,"lat":51.047499,"ele":116},{"lon":13.745483,"lat":51.049137,"ele":116},{"lon":13.747007,"lat":51.050962,"ele":116},{"lon":13.747335,"lat":51.051372,"ele":116},{"lon":13.747512,"lat":51.051647,"ele":114},{"lon":13.747638,"lat":51.051895,"ele":114},{"lon":13.747706,"lat":51.052177,"ele":114},{"lon":13.747728,"lat":51.052386,"ele":117},{"lon":13.747718,"lat":51.052731,"ele":115},{"lon":13.747646,"lat":51.053168,"ele":114.59},{"lon":13.747508,"lat":51.053627,"ele":114.07},{"lon":13.746794,"lat":51.055564,"ele":111.84},{"lon":13.746701,"lat":51.055989,"ele":111.37},{"lon":13.746678,"lat":51.056327,"ele":111},{"lon":13.746727,"lat":51.056351,"ele":111},{"lon":13.746771,"lat":51.056411,"ele":111},{"lon":13.746773,"lat":51.056865,"ele":120},{"lon":13.746806,"lat":51.057117,"ele":120},{"lon":13.746734,"lat":51.057286,"ele":120},{"lon":13.746706,"lat":51.057359,"ele":120},{"lon":13.746481,"lat":51.057845,"ele":118},{"lon":13.746439,"lat":51.058514,"ele":117},{"lon":13.746476,"lat":51.058577,"ele":117},{"lon":13.746458,"lat":51.058846,"ele":117},{"lon":13.746401,"lat":51.058908,"ele":117},{"lon":13.746379,"lat":51.059227,"ele":118},{"lon":13.74624,"lat":51.061096,"ele":114},{"lon":13.746215,"lat":51.061353,"ele":114},{"lon":13.746158,"lat":51.061522,"ele":114},{"lon":13.746125,"lat":51.061888,"ele":115},{"lon":13.746224,"lat":51.062105,"ele":115},{"lon":13.746373,"lat":51.062207,"ele":115},{"lon":13.746749,"lat":51.062301,"ele":115},{"lon":13.746853,"lat":51.062357,"ele":115},{"lon":13.747062,"lat":51.062538,"ele":118},{"lon":13.747191,"lat":51.062718,"ele":118},{"lon":13.747255,"lat":51.062879,"ele":118},{"lon":13.747174,"lat":51.063075,"ele":118},{"lon":13.747099,"lat":51.063383,"ele":114},{"lon":13.747301,"lat":51.063489,"ele":114},{"lon":13.747441,"lat":51.063839,"ele":114}],"sg":[{"index":0,"label":"N\u00fcrnberger Platz","lat":51.03170331486611,"lon":13.727121949195864,"mqtt":"prediction\/133\/R5"},{"index":1,"label":"N\u00fcrnberger Platz","lat":51.03172693027254,"lon":13.727213144302368,"mqtt":"prediction\/133\/R4_4a"},{"index":2,"label":"F.-L\u00f6ffler-Platz","lat":51.0326243068002,"lon":13.730029463768007,"mqtt":"prediction\/421\/FR8"},{"index":3,"label":"F.-L\u00f6ffler-Platz","lat":51.0326243068002,"lon":13.730168938636782,"mqtt":"prediction\/421\/FR6"},{"index":4,"label":"F.-L\u00f6ffler-\/Reichenbachstr.","lat":51.034226721666506,"lon":13.731212317943575,"mqtt":"prediction\/420\/R3"},{"index":5,"label":"F.-L\u00f6ffler-\/Reichenbachstr.","lat":51.03434226207048,"lon":13.731437623500826,"mqtt":"prediction\/420\/FR7_F8"},{"index":6,"label":"Friedrich-List-Platz","lat":51.03869885276055,"lon":13.7333419919014,"mqtt":"prediction\/110\/SG16_R4"},{"index":7,"label":"Wiener Platz","lat":51.04023781369863,"lon":13.734487295150759,"mqtt":"prediction\/10\/R3"},{"index":8,"label":"St. Petersburger\/Sidonienstr.","lat":51.04165698552023,"lon":13.735769391059877,"mqtt":"prediction\/367\/K18"},{"index":9,"label":"St. Petersburger\/Sidonienstr.","lat":51.04220507945901,"lon":13.73633533716202,"mqtt":"prediction\/367\/K5"},{"index":10,"label":"St.-Petersburger Str.","lat":51.04349686905951,"lon":13.73783737421036,"mqtt":"prediction\/272\/SG2_K4"},{"index":11,"label":"St.-Petersburger Str.\/Ferdinandplatz","lat":51.04514275244683,"lon":13.739956319332125,"mqtt":"prediction\/497\/SG2"},{"index":12,"label":"Georgplatz","lat":51.04583161148422,"lon":13.74120891094208,"mqtt":"prediction\/31\/K12,K13"},{"index":13,"label":"Georgplatz","lat":51.04612165432998,"lon":13.741753399372103,"mqtt":"prediction\/31\/K10,K11"},{"index":14,"label":"St. Petersburger\/Kreuzstr.","lat":51.04747741191845,"lon":13.744111061096193,"mqtt":"prediction\/341\/K4,K5,K6"},{"index":15,"label":"Pirnaischer Platz","lat":51.04887528459614,"lon":13.745312690734865,"mqtt":"prediction\/24\/K17_K18_K19_K20"},{"index":16,"label":"Pirnaischer Platz","lat":51.04920493358541,"lon":13.745626509189607,"mqtt":"prediction\/24\/R3"},{"index":17,"label":"Rathenauplatz","lat":51.05109257148705,"lon":13.747321665287018,"mqtt":"prediction\/25\/K17-19"},{"index":18,"label":"Rathenauplatz","lat":51.051224087830796,"lon":13.747351169586183,"mqtt":"prediction\/25\/F11,12"},{"index":19,"label":"Rathenauplatz","lat":51.05160851807882,"lon":13.747608661651613,"mqtt":"prediction\/25\/F9,10"},{"index":20,"label":"Carolaplatz","lat":51.05709726067628,"lon":13.74681204557419,"mqtt":"prediction\/26\/R2"},{"index":21,"label":"Albertplatz","lat":51.06362372666998,"lon":13.747353851795198,"mqtt":"prediction\/4\/R2_R3"}],"distance":4273.266,"ascend":32,"descend":58,"time":998867}'))));
  }

  void updatePosition(
    double lat,
    double lon,
    int speed,
  );

  void startRecommendation();

  void stopRecommendation();

  void dispose() {
    routeStreamController.close();
    recommendationStreamController.close();
  }
}
