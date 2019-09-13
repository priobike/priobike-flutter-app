class SessionInvalid {
  int mode;
  String msg;
  int method;

  SessionInvalid({this.mode, this.msg, this.method});

  SessionInvalid.fromJson(Map<String, dynamic> json) {
    mode = json['mode'];
    msg = json['msg'];
    method = json['method'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['mode'] = this.mode;
    data['msg'] = this.msg;
    data['method'] = this.method;
    return data;
  }
}
