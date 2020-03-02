class DataPoint {
  String trackID;
  double gpsLat;
  double gpsLon;
  double gpsAlt;
  double gpsSpeed;
  String gpsTimestamp;
  double distanceToNextSg;
  double recommendedSpeed;
  bool sgIsGreen;
  int secondsToPhaseChange;
  String nextSgID;
  // TODO: implement further fields: see below

  DataPoint({
    this.trackID,
    this.gpsLat,
    this.gpsLon,
    this.gpsAlt,
    this.gpsSpeed,
    this.gpsTimestamp,
    this.distanceToNextSg,
    this.recommendedSpeed,
    this.sgIsGreen,
    this.secondsToPhaseChange,
    this.nextSgID,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['trackID'] = this.trackID;
    data['gpsLat'] = this.gpsLat;
    data['gpsLon'] = this.gpsLon;
    data['gpsAlt'] = this.gpsAlt;
    data['gpsSpeed'] = this.gpsSpeed;
    data['gpsTimestamp'] = this.gpsTimestamp;
    data['distanceToNextSg'] = this.distanceToNextSg;
    data['recommendedSpeed'] = this.recommendedSpeed;
    data['sgIsGreen'] = this.sgIsGreen;
    data['secondsToPhaseChange'] = this.secondsToPhaseChange;
    data['nextSgID'] = this.nextSgID;
    return data;
  }
}


// datapointFromUser: {
//     "sessionID": "54fe6f47",
//     "trackID": "j123jdij30193u",
//     "gpsAcc": 20,
//     "gpsLat": 51.0302411,
//     "gpsLon": 13.7284526,
//     "gpsAlt": 189.199192,
//     "gpsSpeed": 5.88,
//     "gpsTimestamp": 1525867793000,
//     "gpsUpdateInterval": 10,
//     "gpsBearing": 123,
//     "magneticBearing": 123,    
//     "nextSgID": "420#R3",
//     "nextInstructionText": "Links abbiegen auf Bergstraße, B 170",
//     "nextInstructionSign": "-2",
//     "distanceToNextSg": 119,
//     "recommendedSpeed": 0,
//     "sgIsGreen": true,
//     "secondsToPhaseChange": 23,
//     "batteryPercent": 68,
//     "errorReportCode": 0,
// }

