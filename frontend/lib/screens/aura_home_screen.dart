import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:noor/widgets/chat_bubble.dart';
import 'package:noor/widgets/voice_orb.dart';
import 'package:noor/widgets/property_card.dart';
import 'package:noor/widgets/map_preview.dart';
import 'package:noor/widgets/calculator_card.dart';
import 'package:noor/services/websocket_service.dart';
import 'package:noor/config.dart'; // 🛠️ Fixed missing config import
import 'package:noor/widgets/trend_chart.dart';
import 'package:record/record.dart'; // 🛠️ Fixed missing package import
import 'package:noor/theme.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:io';

class AuraHomeScreen extends StatefulWidget {
  const AuraHomeScreen({Key? key}) : super(key: key);

  @override
  State<AuraHomeScreen> createState() => _AuraHomeScreenState();
}

class _AuraHomeScreenState extends State<AuraHomeScreen> {
  final WebSocketService _wsService = WebSocketService();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ScrollController _scrollController = ScrollController();
  
  bool _isListening = false;
  OrbState _orbState = OrbState.idle;
  String _thinkingStatus = "";
  List<String> _suggestions = ["Find properties", "West Bay", "Near Me 📍"];
  List<Map<String, dynamic>> _conversation = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isKeyboardMode = false;
  
  // 🧩 V5: SEAMLESS UI - Property metadata is kept quiet until requested
  Map<String, dynamic>? _lastFoundProperty;
  
  String _language = "en"; 
  bool _wakeWordEnabled = false;
  String _userName = "User"; // 🧑‍💼 Dynamic Personalization

  @override
  void initState() {
    super.initState();
    _loadConversation();
    _initWebSocket();
  }

  Future<void> _loadConversation() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('conversation_history');
    final userStoredName = prefs.getString('user_full_name');
    if (userStoredName != null) {
      setState(() { _userName = userStoredName; });
    }

    if (saved != null && saved.isNotEmpty) {
      setState(() {
        _conversation = List<Map<String, dynamic>>.from(jsonDecode(saved));
      });
    } else {
      _addNoorGreeting();
    }
  }

  Future<void> _saveConversation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('conversation_history', jsonEncode(_conversation));
  }

  void _addNoorGreeting() {
    final hour = DateTime.now().hour;
    String greeting = "Welcome back.";
    if (hour < 12) greeting = "Good morning.";
    else if (hour < 18) greeting = "Good afternoon.";
    else greeting = "Good evening.";

    setState(() {
      _conversation.add({
        'type': 'text_stream',
        'content': '$greeting $_userName. How can I assist with your real estate needs today?',
        'is_user': false,
        'is_complete': true
      });
    });
    _saveConversation();
  }

  Future<void> _initWebSocket() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedUrl = prefs.getString('server_url');
    String wsUrl = AuraConfig.wsUrl;

    if (savedUrl != null && savedUrl.isNotEmpty) {
      // Convert http(s)://... to ws(s)://... and ensure path is /ws/chat
      String cleanUrl = savedUrl.trim();
      if (cleanUrl.endsWith('/')) cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
      
      if (cleanUrl.startsWith('https://')) {
        wsUrl = cleanUrl.replaceFirst('https://', 'wss://') + '/ws/chat';
      } else if (cleanUrl.startsWith('http://')) {
        wsUrl = cleanUrl.replaceFirst('http://', 'ws://') + '/ws/chat';
      }
    }

    print("Connecting to: $wsUrl");
    _wsService.connect(wsUrl); 

    // 🚀 Personalize Session
    _wsService.sendMessage(jsonEncode({
      "type": "set_profile",
      "full_name": _userName, 
      "priorities": "High ROI & Modern Living"
    }));

    _wsService.messages.listen((data) { 
      final type = data['type'];

      setState(() {
        if (type == 'text_stream') {
          final content = data['content'] ?? "";
          if (content.trim().isEmpty) return; // 🛡️ Filter empty noise
          
          _thinkingStatus = "";
          _orbState = OrbState.idle;
          
          if (_conversation.isNotEmpty && _conversation.last['type'] == 'text_stream' && !(_conversation.last['is_complete'] ?? false)) {
            _conversation.last['content'] += content;
          } else {
            _conversation.add({
              'type': 'text_stream',
              'content': content,
              'is_user': false,
              'is_complete': false
            });
          }
        } 
        else if (type == 'text_final') {
          if (_conversation.isNotEmpty && _conversation.last['type'] == 'text_stream') {
            _conversation.last['is_complete'] = true;
          }
          _thinkingStatus = ""; // 🛡️ Ensure status is cleared
        } 
        else if (type == 'user_input') {
          _conversation.add({
            'type': 'text_stream',
            'content': data['content'],
            'is_user': true,
            'is_complete': true
          });
          _thinkingStatus = "Processing...";
          _orbState = OrbState.idle;
        }
        else if (type == 'ui_trigger') {
          _thinkingStatus = "";
          _orbState = OrbState.idle;
          
          final widgetType = data['widget'];
          final widgetData = data['data'] ?? {};
          
          if (widgetType == 'show_property' || widgetType == 'property_card') {
            _lastFoundProperty = Map<String, dynamic>.from(widgetData as Map);
            
            // 🚀 V5: Ensure property cards ALWAYS get their own bubble or attach to NOOR's last response
            // Never attach to a greeting or a user message.
            if (_conversation.isEmpty || _conversation.last['is_user'] == true || _conversation.length < 2) {
              _conversation.add({
                'type': 'text_stream',
                'content': 'I have identified a premium listing that matches your criteria:',
                'is_user': false,
                'is_complete': true,
                'has_property': true,
                'property_data': _lastFoundProperty
              });
            } else {
               _conversation.last['has_property'] = true;
               _conversation.last['property_data'] = _lastFoundProperty;
            }
          }
          else if (widgetType == 'show_directions') {
            final lat = widgetData['lat'];
            final lng = widgetData['lng'];
            if (lat != null && lng != null) {
               launchUrl(Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'), mode: LaunchMode.externalApplication);
            }
          }
          else if (widgetType == 'share_property') {
             Share.share('Check out this incredible property in Qatar. Found via NOOR AI Concierge.');
          } else {
            _conversation.add({
              'type': 'ui_trigger',
              'widget': widgetType,
              'data': widgetData
            });
          }
        }
        else if (type == 'audio_stream') {
          try {
            _orbState = OrbState.speaking;
            HapticFeedback.lightImpact(); // ⚡ Sync Haptic Kick-off
            final audioBytes = base64Decode(data['audio_b64']);
            _audioPlayer.play(BytesSource(audioBytes)).then((_) {
              if (mounted) {
                setState(() { _orbState = OrbState.idle; });
                _wsService.sendMessage(jsonEncode({"type": "playback_complete"}));
              }
            });
          } catch (e) {
            print("Audio error: $e");
          }
        }
      });
      _scrollToBottom();
      _saveConversation(); // 💾 Persist after every message
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/audio_query.m4a';
        
        const config = RecordConfig(encoder: AudioEncoder.aacLc);
        await _audioRecorder.start(config, path: path);

        setState(() {
          _isListening = true;
          _orbState = OrbState.listening;
          _thinkingStatus = "";
        });
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      print("Start recording error: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isListening = false;
        _orbState = OrbState.idle;
        _thinkingStatus = "Processing...";
      });

      if (path != null) {
        final bytes = await File(path).readAsBytes();
        final base64Audio = base64Encode(bytes);
        _wsService.sendMessage(jsonEncode({
          "type": "audio_input",
          "audio_b64": base64Audio,
          "location": "25.3138407,51.4850558"
        }));
      }
    } catch (e) {
      print("Stop recording error: $e");
    }
  }

  void _onOrbTap() {
    if (_isListening) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _onSearchSubmit(String val) {
    if (val.trim().isEmpty) return;
    setState(() {
      _conversation.add({'type': 'text_stream', 'content': val, 'is_user': true, 'is_complete': true});
      _thinkingStatus = "Processing...";
    });
    _wsService.sendMessage(jsonEncode({
      "type": "chat",
      "text": val,
      "location": "25.3138407,51.4850558"
    }));
    _searchController.clear();
  }

  void _showPropertyModal(Map<String, dynamic> property) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, controller) => Container(
          decoration: BoxDecoration(
            color: AuraTheme.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: AuraTheme.borderLight),
          ),
          child: ListView(
            controller: controller,
            children: [
              const SizedBox(height: 12),
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AuraTheme.textSecondary.withOpacity(0.2), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: PropertyCard(propertyData: property, wsService: _wsService),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversationItem(Map<String, dynamic> item) {
    if (item['type'] == 'text_stream') {
      return ChatBubble(
        content: item['content'],
        isUser: item['is_user'] == true,
        isComplete: item['is_complete'] == true,
        actionLabel: item['has_property'] == true ? 'View Details' : null,
        onAction: item['has_property'] == true ? () => _showPropertyModal(item['property_data']) : null,
      );
    } else if (item['type'] == 'ui_trigger') {
      if (item['widget'] == 'map_view') {
        return MapPreview(locationName: item['data']['location'] ?? 'Unknown Location');
      } else if (item['widget'] == 'show_calculator') {
        return CalculatorCard(price: item['data']['price']?.toDouble() ?? 3000000.0);
      } else if (item['widget'] == 'show_trends' || item['widget'] == 'trend_chart') {
        final List<double> history = List<double>.from(item['data']['history'] ?? [2.1, 2.3, 2.2, 2.5, 2.8, 3.1]);
        return TrendChart(data: history, title: item['data']['district'] ?? 'Doha');
      } else if (item['widget'] == 'book_viewing') {
        return _buildBookingCard(item['data']);
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildBookingCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: AuraTheme.solidDecoration(radius: 24),
      child: Column(
        children: [
          const Icon(Icons.verified_rounded, color: Colors.tealAccent, size: 40),
          const SizedBox(height: 16),
          const Text("VIEWING CONFIRMED", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text(data['date'] ?? "Scheduled", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w300)),
          const SizedBox(height: 24),
          const Divider(color: AuraTheme.borderLight),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.notifications_active_outlined, size: 14, color: AuraTheme.textSecondary),
              const SizedBox(width: 8),
              Text("I'VE ADDED THIS TO YOUR CALENDAR", style: const TextStyle(fontSize: 10, color: AuraTheme.textSecondary, letterSpacing: 1)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                itemCount: _conversation.length,
                itemBuilder: (context, index) => _buildConversationItem(_conversation[index]),
              ),
            ),
            _buildThinkingIndicator(),
            _buildVoiceZone(),
          ],
        ),
      ),
    );
  }

  Widget _buildThinkingIndicator() {
    if (_thinkingStatus.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: AuraTheme.accentBlue)),
          const SizedBox(width: 16),
          Text(_thinkingStatus.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _buildVoiceZone() {
    // Determine status label text
    String statusLabel = '';
    if (_isListening) {
      statusLabel = 'LISTENING...';
    } else if (_thinkingStatus.isNotEmpty) {
      statusLabel = _thinkingStatus.toUpperCase();
    } else if (!_isKeyboardMode) {
      statusLabel = 'TAP TO SPEAK';
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.only(bottom: 24),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isKeyboardMode)
                GestureDetector(
                  onTap: _onOrbTap,
                  child: VoiceOrb(isListening: _isListening, state: _orbState),
                ),
              if (_isKeyboardMode)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: _onSearchSubmit,
                    autofocus: true,
                    style: const TextStyle(color: AuraTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search properties...',
                      hintStyle: TextStyle(color: AuraTheme.textSecondary.withOpacity(0.5)),
                      prefixIcon: const Icon(Icons.search_rounded, color: AuraTheme.textSecondary, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AuraTheme.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AuraTheme.borderLight),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  statusLabel,
                  key: ValueKey(statusLabel),
                  style: TextStyle(
                    color: _isListening
                        ? AuraTheme.accentBlue
                        : AuraTheme.textSecondary,
                    fontSize: 11,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 20,
            bottom: 0,
            child: IconButton(
              icon: Icon(_isKeyboardMode ? Icons.mic_rounded : Icons.keyboard_rounded),
              color: AuraTheme.textSecondary,
              onPressed: () => setState(() => _isKeyboardMode = !_isKeyboardMode),
            ),
          ),
        ],
      ),
    );
  }
}
