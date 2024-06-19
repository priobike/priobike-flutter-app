class NodeStatus {
  /// The current load status of the ingress node.
  final bool warning;

  /// The timestamp of the current load status data.
  final DateTime timestamp;

  NodeStatus({required this.warning, required this.timestamp});

  factory NodeStatus.fromJson(Map<String, dynamic> json) => NodeStatus(
        warning: json['warning'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] * 1000),
      );

  Map<String, dynamic> toJson() => {
        'warning': warning,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };
}
