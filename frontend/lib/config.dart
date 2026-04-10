class AuraConfig {
  // 🎙️ DEMO CONFIGURATION
  // Set isRemote to true if using Ngrok for the client demo away from home
  static const bool isRemote = true;

  // 🌐 HOME NETWORK (Wi-Fi)
  static const String serverIp = "192.168.100.67";
  static const String homeBaseUrl = "http://$serverIp:8000";
  static const String homeWsUrl = "ws://$serverIp:8000/ws/chat";

  // 🚀 REMOTE DEMO (Ngrok) 
  // Update these URLs after running 'ngrok http 8000'
  static const String remoteBaseUrl = "https://7ba2-2001-1a10-17fb-5700-987a-566b-9c92-8b4a.ngrok-free.app";
  static const String remoteWsUrl = "wss://7ba2-2001-1a10-17fb-5700-987a-566b-9c92-8b4a.ngrok-free.app/ws/chat";

  // 🧠 Active URLs
  static const String baseUrl = isRemote ? remoteBaseUrl : homeBaseUrl;
  static const String wsUrl = isRemote ? remoteWsUrl : homeWsUrl;
}
