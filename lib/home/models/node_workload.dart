class NodeWorkload {
  /// The current load status of the ingress node.
  final double ingress;

  /// The current load status of the worker node.
  final double worker;

  /// The current load status of the stateful node.
  final double stateful;

  /// The timestamp of the current load status data.
  final DateTime timestamp;

  NodeWorkload({required this.ingress, required this.worker, required this.stateful, required this.timestamp});

  factory NodeWorkload.fromJson(Map<String, dynamic> json) => NodeWorkload(
        ingress: json['ingress'],
        worker: json['worker'],
        stateful: json['stateful'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      );

  Map<String, dynamic> toJson() => {
        'ingress': ingress,
        'worker': worker,
        'stateful': stateful,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };
}
