import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:noor/widgets/chat_bubble.dart';
import 'package:noor/widgets/voice_orb.dart';
import 'package:noor/widgets/property_card.dart';
import 'package:noor/widgets/map_preview.dart';
import 'package:noor/widgets/calculator_card.dart';
import 'package:noor/services/websocket_service.dart';
import 'package:noor/config.dart';
import 'package:noor/widgets/trend_chart.dart';
import 'package:record/record.dart';
import 'package:noor/theme.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:noor/services/voice_interface_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:noor/services/auth_service.dart';
import 'package:noor/screens/login_screen.dart';

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
  List<Map<String, dynamic>> _conversation = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isKeyboardMode = false;
  
  Map<String, dynamic>? _lastFoundProperty;
  String _userName = "NOOR Member"; 
  String _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  String _sessionTitle = "New Conversation";

  final _voiceService = VoiceInterfaceService();
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadConversation();
    _initWebSocket();
    _voiceService.triggerRecording.addListener(_onOrbTap);
  }

  @override
  void dispose() {
    _voiceService.triggerRecording.removeListener(_onOrbTap);
    _wsService.disconnect();
    _searchController.dispose();
    _scrollController.dispose();
    if (_isListening) _audioRecorder.stop();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadConversation() async {
    final prefs = await SharedPreferences.getInstance();
    final userStoredName = prefs.getString('user_full_name');
    if (userStoredName != null) {
      setState(() { _userName = userStoredName; });
    }

    final sessionsJson = prefs.getString('chat_sessions_v2');
    if (sessionsJson != null) {
      List<dynamic> sessions = jsonDecode(sessionsJson);
      if (sessions.isNotEmpty) {
        var activeSession = sessions.last;
        setState(() {
          _sessionId = activeSession['id'];
          _sessionTitle = activeSession['title'];
          _conversation = List<Map<String, dynamic>>.from(activeSession['messages']);
        });
        return;
      }
    }
    _addNoorGreeting();
  }

  Future<void> _saveConversation() async {
    final prefs = await SharedPreferences.getInstance();
    List<dynamic> sessions = [];
    final sessionsJson = prefs.getString('chat_sessions_v2');
    if (sessionsJson != null) {
      sessions = jsonDecode(sessionsJson);
    }

    int existingIndex = sessions.indexWhere((s) => s['id'] == _sessionId);
    if (_sessionTitle == "New Conversation" && _conversation.length > 1) {
      _sessionTitle = _conversation[1]['content'].toString().substring(0, min(30, _conversation[1]['content'].toString().length)) + "...";
    }

    final currentSessionData = {
      'id': _sessionId,
      'title': _sessionTitle,
      'timestamp': DateTime.now().toIso8601String(),
      'messages': _conversation,
    };

    if (existingIndex >= 0) {
      sessions[existingIndex] = currentSessionData;
    } else {
      sessions.add(currentSessionData);
    }

    await prefs.setString('chat_sessions_v2', jsonEncode(sessions));
  }

  void _startNewSession() {
    setState(() {
      _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      _sessionTitle = "New Conversation";
      _conversation = [];
      _addNoorGreeting();
    });
    _saveConversation();
  }

  void _loadSession(Map<String, dynamic> sessionData) {
    setState(() {
      _sessionId = sessionData['id'];
      _sessionTitle = sessionData['title'];
      _conversation = List<Map<String, dynamic>>.from(sessionData['messages']);
    });
    Navigator.pop(context);
    _scrollToBottom();
  }

  void _showChatHistoryModal() async {
    final prefs = await SharedPreferences.getInstance();
    List<dynamic> sessions = [];
    final sessionsJson = prefs.getString('chat_sessions_v2');
    if (sessionsJson != null) {
      sessions = jsonDecode(sessionsJson);
    }
    
    sessions = sessions.reversed.toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AuraTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AuraTheme.textSecondary.withOpacity(0.2), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("CHAT HISTORY", style: TextStyle(color: AuraTheme.textSecondary, letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () { Navigator.pop(context); _startNewSession(); },
                  icon: const Icon(Icons.add, size: 16, color: AuraTheme.accentBlue),
                  label: const Text("NEW CHAT", style: TextStyle(color: AuraTheme.accentBlue, letterSpacing: 1, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(color: AuraTheme.borderLight),
            Expanded(
              child: sessions.isEmpty ? 
                const Center(child: Text("No past conversations found.", style: TextStyle(color: AuraTheme.textSecondary))) :
                ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final isActive = session['id'] == _sessionId;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(session['title'], style: TextStyle(color: isActive ? AuraTheme.accentBlue : AuraTheme.textPrimary, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                      subtitle: Text(session['timestamp'].toString().split('T')[0], style: const TextStyle(color: AuraTheme.textSecondary, fontSize: 12)),
                      trailing: isActive ? const Icon(Icons.check_circle, color: AuraTheme.accentBlue, size: 16) : null,
                      onTap: () => _loadSession(session as Map<String, dynamic>),
                    );
                  },
                ),
            ),
            const Divider(color: AuraTheme.borderLight),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text("SIGN OUT", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1)),
              onTap: () async {
                await _authService.logout();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _getGeoLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return "none,none";
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return "none,none";
      }
      if (permission == LocationPermission.deniedForever) return "none,none";
      
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      return "${position.latitude},${position.longitude}";
    } catch (e) {
      print("Location fetch error: $e");
      return "none,none";
    }
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
        'content': "$greeting $_userName. How can I assist with your real estate needs today?",
        'translation': 'مرحباً $_userName. كيف يمكنني مساعدتك في احتياجاتك العقارية اليوم؟',
        'is_user': false,
        'is_complete': true
      });
    });
  }

  Future<void> _initWebSocket() async {
    String wsUrl = AuraConfig.wsUrl; 
    
    final prefs = await SharedPreferences.getInstance();
    final customUrl = prefs.getString('noor_api_url');
    if (customUrl != null && customUrl.isNotEmpty) {
      final cleanUrl = customUrl.replaceAll(RegExp(r'/docs$'), '').replaceAll(RegExp(r'/$'), '');
      if (cleanUrl.startsWith('https')) {
        wsUrl = cleanUrl.replaceFirst('https://', 'wss://') + '/ws/chat';
      } else if (cleanUrl.startsWith('http')) {
        wsUrl = cleanUrl.replaceFirst('http://', 'ws://') + '/ws/chat';
      }
    }

    print("Connecting to: $wsUrl");
    _wsService.connect(wsUrl); 

    _wsService.sendMessage(jsonEncode({
      "type": "set_profile",
      "full_name": _userName, 
      "priorities": "Premium Lifestyle & Convenience"
    }));

    _wsService.messages.listen((data) { 
      final type = data['type'];

      setState(() {
        if (type == 'user_transcription') {
          _conversation.add({
            'type': 'text_stream',
            'content': data['text'],
            'is_user': true,
            'is_complete': true
          });
          _thinkingStatus = "Searching...";
        }
        else if (type == 'text_stream') {
          final content = data['content'] ?? "";
          if (content.trim().isEmpty) return; 
          
          _thinkingStatus = "";
          _orbState = OrbState.idle;
          
          if (_conversation.isNotEmpty && _conversation.last['type'] == 'text_stream' && !(_conversation.last['is_complete'] ?? false) && !(_conversation.last['is_user'] ?? false)) {
            _conversation.last['content'] += content;
          } else {
            _conversation.add({
              'type': 'text_stream',
              'content': content,
              'is_user': false,
              'is_complete': false,
              'property_data': null, 
            });
          }
        } 
        else if (type == 'text_final') {
          if (_conversation.isNotEmpty && _conversation.last['type'] == 'text_stream' && !(_conversation.last['is_user'] ?? false)) {
            _conversation.last['is_complete'] = true;
            _conversation.last['translation'] = data['translation'] ?? "";
          }
          _thinkingStatus = "";
        } 
        else if (type == 'ui_trigger') {
          final widgetType = data['widget'];
          final widgetData = data['data'] ?? {};

          if (widgetType == 'show_property') {
            _lastFoundProperty = Map<String, dynamic>.from(widgetData as Map);
            if (_conversation.isNotEmpty && !(_conversation.last['is_user'] ?? false)) {
              _conversation.last['property_data'] = _lastFoundProperty;
            }
          }
          else if (widgetType == 'show_properties_carousel') {
             final properties = List<Map<String, dynamic>>.from(widgetData['properties'] ?? []);
             if (_conversation.isNotEmpty && !(_conversation.last['is_user'] ?? false)) {
               _conversation.last['property_data'] = properties;
             }
          }
          else if (widgetType == 'show_directions') {
            final lat = widgetData['lat'];
            final lng = widgetData['lng'];
            if (lat != null && lng != null) {
               launchUrl(Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'), mode: LaunchMode.externalApplication);
            }
          }
          else if (widgetType == 'book_viewing') {
            _conversation.add({
              'type': 'ui_trigger',
              'widget': 'book_viewing',
              'data': widgetData
            });
          }

          _thinkingStatus = "";
          _orbState = OrbState.idle;
        }
        else if (type == 'audio_stream') {
          try {
            _orbState = OrbState.speaking;
            HapticFeedback.lightImpact(); 
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
      _saveConversation(); 
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
    } catch (e) { print("Record start error: $e"); }
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
        final loc = await _getGeoLocation();
        _wsService.sendMessage(jsonEncode({
          "type": "audio_input",
          "audio_b64": base64Encode(bytes),
          "location": loc
        }));
      }
    } catch (e) { print("Record stop error: $e"); }
  }

  void _onOrbTap() {
    if (_isListening) { _stopRecording(); } else { _startRecording(); }
  }

  void _onSearchSubmit(String val) async {
    if (val.trim().isEmpty) return;
    setState(() {
      _conversation.add({'type': 'text_stream', 'content': val, 'is_user': true, 'is_complete': true});
      _thinkingStatus = "Processing...";
    });
    
    final loc = await _getGeoLocation();
    _wsService.sendMessage(jsonEncode({
      "type": "chat",
      "text": val,
      "location": loc
    }));
    _searchController.clear();
  }

  void _showPropertyModal(Map<String, dynamic> property) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(color: AuraTheme.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          child: ListView(
            controller: scrollController,
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

  void _showPropertiesCarouselModal(List<Map<String, dynamic>> properties) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(color: AuraTheme.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AuraTheme.textSecondary.withOpacity(0.2), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text("SWIPE TO EXPLORE", style: TextStyle(color: AuraTheme.textSecondary, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: PageView.builder(
                  controller: PageController(viewportFraction: 0.9),
                  itemCount: properties.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: PropertyCard(propertyData: properties[index], wsService: _wsService),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversationItem(Map<String, dynamic> item) {
    if (item['type'] == 'text_stream') {
      final propertyData = item['property_data'];
      final isList = propertyData is List;

      return ChatBubble(
        content: item['content'],
        translation: item['translation'] ?? "",
        isUser: item['is_user'] == true,
        isComplete: item['is_complete'] == true,
        actionLabel: propertyData != null ? (isList ? 'VIEW SET (${(propertyData as List).length})' : 'VIEW DETAILS') : null,
        onAction: propertyData != null ? () {
          if (isList) {
            _showPropertiesCarouselModal(List<Map<String, dynamic>>.from(propertyData as List));
          } else {
            _showPropertyModal(propertyData as Map<String, dynamic>);
          }
        } : null,
      );
    } else if (item['type'] == 'ui_trigger') {
       if (item['widget'] == 'book_viewing') {
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_active_outlined, size: 14, color: AuraTheme.textSecondary),
              SizedBox(width: 8),
              Text("I'VE ADDED THIS TO YOUR CALENDAR", style: TextStyle(fontSize: 10, color: AuraTheme.textSecondary, letterSpacing: 1)),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text("NOOR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2, color: AuraTheme.textPrimary)),
                   IconButton(
                     icon: const Icon(Icons.history_rounded, color: AuraTheme.textSecondary),
                     onPressed: _showChatHistoryModal,
                   )
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                itemCount: _conversation.length,
                itemBuilder: (context, index) => _buildConversationItem(_conversation[index]),
              ),
            ),
            _buildVoiceZone(),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceZone() {
    String statusLabel = 'TAP THE BLUE ORB BELOW TO SPEAK';
    if (_isListening) statusLabel = 'LISTENING...';
    else if (_thinkingStatus.isNotEmpty) statusLabel = _thinkingStatus.toUpperCase();

    // Propagate state to voice service so the MainLayout orb updates visually
    _voiceService.isListening.value = _isListening;
    _voiceService.status.value = statusLabel;

    return Container(
      padding: const EdgeInsets.only(bottom: 24, top: 16),
      child: Column(
        children: [
          if (_isKeyboardMode) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _searchController,
                onSubmitted: _onSearchSubmit,
                autofocus: true,
                style: const TextStyle(color: AuraTheme.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Message NOOR...',
                  hintStyle: TextStyle(color: AuraTheme.textSecondary.withOpacity(0.4)),
                  prefixIcon: const Icon(Icons.maps_home_work_outlined, color: AuraTheme.textSecondary),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send_rounded, color: AuraTheme.accentBlue),
                    onPressed: () => _onSearchSubmit(_searchController.text),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => setState(() => _isKeyboardMode = false),
              icon: const Icon(Icons.mic_none_rounded, size: 18, color: AuraTheme.accentBlue),
              label: const Text("SWITCH TO VOICE", style: TextStyle(color: AuraTheme.accentBlue, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_rounded, color: AuraTheme.textSecondary),
                  onPressed: () => setState(() => _isKeyboardMode = true),
                ),
                const SizedBox(width: 8),
                Text(statusLabel, style: TextStyle(color: AuraTheme.textSecondary.withOpacity(0.6), fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                const SizedBox(width: 48), // Balance the row
              ],
            ),
          ],
        ],
      ),
    );
  }
}

