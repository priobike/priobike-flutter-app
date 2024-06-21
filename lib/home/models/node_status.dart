class NodeStatus {
  /// If the user is recommended to use the fallback backend.
  final bool recommendFallback;

  /// If the node has a warning.
  final bool warning;

  /// The timestamp of the current load status data.
  final DateTime timestamp;

  NodeStatus({required this.recommendFallback, required this.warning, required this.timestamp});

  factory NodeStatus.fromJson(Map<String, dynamic> json) => NodeStatus(
        recommendFallback: json['recommend_fallback'],
        warning: json['warning'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] * 1000),
      );

  Map<String, dynamic> toJson() => {
        'recommend_fallback': recommendFallback,
        'warning': warning,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };
}
