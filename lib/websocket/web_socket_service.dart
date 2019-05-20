import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService{
  WebSocketChannel(){
    final channel = IOWebSocketChannel.connect('ws://vkwvlprad.vkw.tu-dresden.de:20042/socket');


  }


}