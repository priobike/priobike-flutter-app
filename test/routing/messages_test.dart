import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:priobike/ride/messages/ride.dart';
import 'package:priobike/routing/messages/routing.dart';

void main() {
  test('Load an example route response', () async {
    final file1 = File('test_resources/routes.json');
    final json1 = jsonDecode(await file1.readAsString());
    final response = RoutesResponse.fromJson(json1);
    final route = response.routes[0];
    final request = SelectRideRequest(
      sessionId: "abc", 
      route: route.route, 
      navigationPath: route.path, 
      signalGroups: { for (final signalGroup in route.signalGroups) signalGroup.id: signalGroup }
    ).toJson();
    jsonEncode(request);
  });
}