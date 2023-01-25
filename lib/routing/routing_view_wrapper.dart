import 'package:flutter/material.dart';
import 'package:priobike/routing/views/main.dart';
import 'package:priobike/routing/views_beta/main.dart';
import 'package:priobike/settings/models/routing_view.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';

class RoutingViewWrapper extends StatefulWidget {

  const RoutingViewWrapper({Key? key}) : super(key: key);

  @override
  RoutingViewWrapperState createState() => RoutingViewWrapperState();
}

class RoutingViewWrapperState extends State<RoutingViewWrapper> {

  /// The associated settings service, which is injected by the provider.
  late Settings settings;

  @override
  void didChangeDependencies() {
    settings = Provider.of<Settings>(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return settings.routingView == RoutingViewOption.stable ? const RoutingView() : const RoutingViewNew();
  }
}
