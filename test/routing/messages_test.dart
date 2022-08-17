import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:priobike/routing/messages/routing.dart';

void main() {
  test('Load an example route response', () async {
    final file = File('test_resources/example-route-response.json');
    final json = jsonDecode(await file.readAsString());
    RouteResponse.fromJson(json);
  });
}