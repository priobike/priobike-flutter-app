import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:priobike/common/logger.dart';
import 'package:priobike/ride/messages/recommendation.dart';
import 'package:priobike/ride/messages/userposition.dart';
import 'package:priobike/ride/messages/navigation.dart';
import 'package:priobike/session/services/session.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:provider/provider.dart';

class RecommendationService with ChangeNotifier {
  Logger log = Logger("RecommendationService");

  /// A boolean indicating if the navigation is active.
  var navigationIsActive = false;

  /// The web socket channel to the backend.
  WebSocketChannel? socket;

  /// The peer used to communicate JSON RPC messages to the backend.
  Peer? jsonRPCPeer;

  /// The current recommendation from the server.
  Recommendation? currentRecommendation;

  /// An indicator if the data of this notifier changed.
  Map<String, bool> needsLayout = {};

  RecommendationService({this.currentRecommendation});

  /// A callback that is executed when the websocket closes.
  Future<void> onCloseWebsocket(BuildContext context) async {
    // If this is on purpose, we don't do anything.
    if (!navigationIsActive) return;
    // Otherwise, we attempt to reconnect.
    log.w("Reconnecting websocket after disconnect: ${socket?.closeCode} ${socket?.closeReason}");
    // Connect to the websocket channel.
    await Future.delayed(const Duration(milliseconds: 500), () => connectWebsocket(context));
  }

  /// A callback that is executed when a new recommendation arrives.
  Future<void> onNewRecommendation(Parameters params) async {
    try {
      currentRecommendation = Recommendation.fromJsonRPC(params);
      if (currentRecommendation!.error) {
        log.w("Recommendation arrived with set error: ${currentRecommendation!.toJson()}");
      } else {
        log.i("Got recommendation via websocket.");
      }
    } catch (error) { 
      log.e("Recommendation could not be decoded: $error"); 
    }
  }

  /// Connect the websocket.
  Future<void> connectWebsocket(BuildContext context) async {
    // Get the session from the context and verify that it is active.
    final session = Provider.of<SessionService>(context, listen: false);
    if (!session.isActive()) return;
    // Connect the websocket.
    log.i("Connecting to session websocket.");
    final settings = Provider.of<SettingsService>(context, listen: false);
    final baseUrl = settings.backend.path;
    final wsUrl = "wss://$baseUrl/session-wrapper/websocket/sessions/${session.sessionId!}";
    socket = WebSocketChannel.connect(Uri.parse(wsUrl));
    jsonRPCPeer = Peer(socket!.cast<String>());
    jsonRPCPeer!.listen().then((_) => onCloseWebsocket(context));
    jsonRPCPeer!.registerMethod("RecommendationUpdate", onNewRecommendation);
    log.i("Connected to session websocket.");
  }

  /// Connect the websocket and start the navigation.
  Future<void> startNavigation(BuildContext context) async {
    // Do nothing if the navigation has already been started.
    if (navigationIsActive) return;
    // Mark that navigation is now active.
    navigationIsActive = true;
    // Connect to the websocket channel.
    await connectWebsocket(context);
    // Send a navigation request.
    final req = const NavigationRequest(active: true).toJson();
    log.i("Sending navigation request via websocket: $req");
    await jsonRPCPeer?.sendRequest("Navigation", req);
  }

  /// Update the current user position and send it to the server.
  Future<void> updatePosition(BuildContext context, Position position) async {
    // Get the session from the context and verify that it is active.
    final session = Provider.of<SessionService>(context, listen: false);
    if (!session.isActive()) return;
    // Start the navigation if it isn't active.
    if (!navigationIsActive) await startNavigation(context);
    // Send the position update.
    final req = UserPosition(
      lat: position.latitude,
      lon: position.longitude,
      speed: position.speed,
      accuracy: position.accuracy,
      heading: position.heading,
      timestamp: position.timestamp,
    ).toJson();
    log.i("Sending user position via websocket: $req");
    jsonRPCPeer?.sendNotification('PositionUpdate', req);
  }

  /// End the navigation and disconnect the websocket.
  Future<void> stopNavigation(BuildContext context) async {
    // Do nothing if the navigation has already been ended.
    if (!navigationIsActive) return;
    // Mark that navigation is inactive.
    navigationIsActive = false;
    // Send a navigation request.
    final req = const NavigationRequest(active: false).toJson();
    log.i("Sending navigation request via websocket: $req");
    await jsonRPCPeer?.sendRequest('Navigation', req);
    // Get the session from the context and close it.
    final session = Provider.of<SessionService>(context, listen: false);
    await session.closeSession();
    // Close the json rpc peer.
    await jsonRPCPeer?.close();
  }

  @override 
  void notifyListeners() {
    needsLayout.updateAll((key, value) => true);
    super.notifyListeners();
  }
}