import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:priobike/routing/messages/routing.dart';

void main() {
  test('Load an example route response', () async {
    final file1 = File('test_resources/example-route-response-1.json');
    final json1 = jsonDecode(await file1.readAsString());
    RouteResponse.fromJson(json1);

    final file2 = File('test_resources/example-route-response-2.json');
    final json2 = jsonDecode(await file2.readAsString());
    RouteResponse.fromJson(json2);
  });
}