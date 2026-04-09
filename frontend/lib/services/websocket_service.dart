import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';

class WebSocketService {
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _controller = StreamController.broadcast();

  Stream<Map<String, dynamic>> get messages => _controller.stream;

  void connect(String url) {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      
      _channel!.stream.listen((message) {
        try {
          final decoded = jsonDecode(message);
          _controller.add(decoded);
        } catch (e) {
          print("JSON Decode error: $e");
        }
      },
      onError: (error) {
        print("WebSocket Error: $error");
      },
      onDone: () {
        print("WebSocket Disconnected");
      });
    } catch (e) {
      print("WebSocket Connection Exception: $e");
    }
  }

  void sendMessage(String text) {
    if (_channel != null) {
      _channel!.sink.add(text);
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _controller.close();
  }
}
