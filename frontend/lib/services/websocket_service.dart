import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';

class WebSocketService {
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _controller = StreamController.broadcast();
  bool _isConnected = false;
  String? _lastUrl;
  Timer? _reconnectTimer;

  Stream<Map<String, dynamic>> get messages => _controller.stream;
  bool get isConnected => _isConnected;

  void connect(String url) {
    _lastUrl = url;
    _reconnectTimer?.cancel();
    
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _isConnected = true;
      
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
        _handleDisconnect();
      },
      onDone: () {
        print("WebSocket Disconnected");
        _handleDisconnect();
      });
    } catch (e) {
      print("WebSocket Connection Exception: $e");
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (_lastUrl != null) {
        print("Attempting to reconnect to $_lastUrl...");
        connect(_lastUrl!);
      }
    });
  }

  void sendMessage(String text) {
    if (_channel != null && _isConnected) {
      try {
        _channel!.sink.add(text);
      } catch (e) {
        print("Error sending message: $e");
        _handleDisconnect();
      }
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _isConnected = false;
    _channel?.sink.close();
    _controller.close();
  }
}
