import 'package:flutter/material.dart';

class VoiceInterfaceService {
  static final VoiceInterfaceService _instance = VoiceInterfaceService._internal();
  factory VoiceInterfaceService() => _instance;
  VoiceInterfaceService._internal();

  // Trigger for the home screen to start recording
  final ValueNotifier<bool> triggerRecording = ValueNotifier<bool>(false);
  
  // Status of the current recording/processing
  final ValueNotifier<String> status = ValueNotifier<String>('TAP TO SPEAK');
  
  // To notify the UI that it should show/hide the wave animation on the bottom bar
  final ValueNotifier<bool> isListening = ValueNotifier<bool>(false);

  void start() {
    triggerRecording.value = !triggerRecording.value; // Toggle to trigger
  }
}
