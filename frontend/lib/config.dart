class AuraConfig {
  // 🎙️ PRODUCTION CONFIGURATION
  static const bool isRemote = true;

  // 🌐 VPS LIVE (Production)
  static const String liveBaseUrl = "https://noor.tenancyos.com";
  static const String liveWsUrl = "wss://noor.tenancyos.com/ws/chat";

  // 🌐 HOME NETWORK (Wi-Fi)
  static const String serverIp = "192.168.100.67";
  static const String homeBaseUrl = "http://$serverIp:8000";
  static const String homeWsUrl = "ws://$serverIp:8000/ws/chat";

  // 🧠 Active URLs
  static const String baseUrl = isRemote ? liveBaseUrl : homeBaseUrl;
  static const String wsUrl = isRemote ? liveWsUrl : homeWsUrl;
}
