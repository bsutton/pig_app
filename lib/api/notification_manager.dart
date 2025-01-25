import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pig_common/pig_common.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'settings.dart';

/// We use web sockets for two way communications so that
/// we can get notifications from the server
class NotificationManager with WidgetsBindingObserver {
  factory NotificationManager() => instance;
  NotificationManager._();
  static NotificationManager instance = NotificationManager._();

  late WebSocketChannel _channel;
  bool _isConnected = false;

  /// List of listeners to receive notifications.
  final List<void Function(Notice)> _listeners = [];

  /// Initialize the WebSocket and listen for app lifecycle events.
  void init() {
    WidgetsBinding.instance.addObserver(this);
    _connectWebSocket();
  }

  /// Dispose of resources and clean up.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disconnectWebSocket();
    _listeners.clear();
  }

  /// App lifecycle handling.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _disconnectWebSocket();
    } else if (state == AppLifecycleState.resumed) {
      _connectWebSocket();
    }
  }

  /// Subscribe a listener to notifications.
  void addListener(void Function(Notice) listener) {
    _listeners.add(listener);
  }

  /// Unsubscribe a listener from notifications.
  void removeListener(void Function(Map<String, dynamic>) listener) {
    _listeners.remove(listener);
  }

  /// Notify all listeners of a new message.
  void _notifyListeners(Notice notice) {
    for (final listener in _listeners) {
      listener(notice);
    }
  }

  /// Connect to the WebSocket server.
  void _connectWebSocket() {
    if (_isConnected) {
      return;
    }

    try {
      _channel = IOWebSocketChannel.connect('$webSocketUrl/monitor');
      _isConnected = true;

      // Listen for incoming messages.
      (_channel.stream as Stream<Object?>).listen(
        (message) {
          final data = Notice.fromJson(
              jsonDecode(message! as String) as Map<String, dynamic>);
          _notifyListeners(data);
        },
        onError: (Object error) {
          print('WebSocket error: $error');
          _isConnected = false;
        },
        onDone: () {
          print('WebSocket connection closed');
          _isConnected = false;
        },
      );

      print('WebSocket connected');
    } catch (e) {
      print('Error connecting to WebSocket: $e');
      _isConnected = false;
    }
  }

  /// Disconnect from the WebSocket server.
  void _disconnectWebSocket() {
    if (_isConnected) {
      unawaited(_channel.sink.close());
      _isConnected = false;
      print('WebSocket disconnected');
    }
  }
}
