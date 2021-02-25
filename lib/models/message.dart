class Message {
  String id;
  String type;
  String payload;

  Message({this.id, this.type, this.payload});

  Message.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    type = json['type'];
    payload = json['payload'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['type'] = this.type;
    data['payload'] = this.payload;
    return data;
  }
}
