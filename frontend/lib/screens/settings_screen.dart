import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../config.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ─── Persisted State ───────────────────────────────────────────────────────
  String _language = 'en';
  bool _wakeWordEnabled = false;
  bool _hapticEnabled = true;
  bool _voiceResponseEnabled = true;
  String _serverUrl = AuraConfig.baseUrl;
  String _responseSpeed = 'Instant';
  String _userName = 'User';

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _language = prefs.getString('language') ?? 'en';
      _wakeWordEnabled = prefs.getBool('wake_word') ?? false;
      _hapticEnabled = prefs.getBool('haptic') ?? true;
      _voiceResponseEnabled = prefs.getBool('voice_response') ?? true;
      _serverUrl = prefs.getString('server_url') ?? AuraConfig.baseUrl;
      _responseSpeed = prefs.getString('response_speed') ?? 'Instant';
      _userName = prefs.getString('user_full_name') ?? 'User';
      _loading = false;
    });
  }

  Future<void> _save(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
    if (value is int) await prefs.setInt(key, value);
  }

  String _t(String en, String ar) => _language == 'ar' ? ar : en;

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AuraTheme.background,
        body: Center(child: CircularProgressIndicator(color: AuraTheme.accentBlue, strokeWidth: 1)),
      );
    }

    return Directionality(
      textDirection: _language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AuraTheme.background,
        appBar: AppBar(
          title: Text(
            _t('S E T T I N G S', 'الإعدادات'),
            style: const TextStyle(letterSpacing: 4.0, fontWeight: FontWeight.w800, fontSize: 14, color: AuraTheme.textPrimary),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AuraTheme.textPrimary, size: 18),
            onPressed: () => Navigator.pop(context, _language),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── INTELLIGENCE UNIT ──────────────────────────────────────────
              _sectionHeader(_t('INTELLIGENCE UNIT', 'وحدة الذكاء')),

              // Language Selector
              _tile(
                icon: Icons.language_rounded,
                title: _t('Language', 'اللغة'),
                subtitle: _t('Response language for NOOR', 'لغة ردود نور'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _langChip('en', 'EN'),
                    const SizedBox(width: 8),
                    _langChip('ar', 'ع'),
                  ],
                ),
              ),

              // Wake Word
              _tile(
                icon: Icons.record_voice_over_rounded,
                title: _t('Wake Word', 'كلمة التفعيل'),
                subtitle: _t(
                  _wakeWordEnabled ? 'Active — "Hey NOOR"' : 'Tap orb to activate',
                  _wakeWordEnabled ? 'نشط — "يا نور"' : 'انقر الكرة للتفعيل',
                ),
                trailing: Switch(
                  value: _wakeWordEnabled,
                  onChanged: (v) {
                    setState(() => _wakeWordEnabled = v);
                    _save('wake_word', v);
                  },
                  activeColor: AuraTheme.accentBlue,
                  activeTrackColor: AuraTheme.accentBlue.withOpacity(0.2),
                ),
              ),

              // Voice Responses
              _tile(
                icon: Icons.volume_up_rounded,
                title: _t('Voice Responses', 'الردود الصوتية'),
                subtitle: _t(
                  _voiceResponseEnabled ? 'NOOR speaks her answers' : 'Text only mode',
                  _voiceResponseEnabled ? 'نور تتحدث بإجاباتها' : 'وضع النص فقط',
                ),
                trailing: Switch(
                  value: _voiceResponseEnabled,
                  onChanged: (v) {
                    setState(() => _voiceResponseEnabled = v);
                    _save('voice_response', v);
                  },
                  activeColor: AuraTheme.accentBlue,
                  activeTrackColor: AuraTheme.accentBlue.withOpacity(0.2),
                ),
              ),

              // 🎙️ NOOR V5: VOICE IDENTIFICATION
              _tile(
                icon: Icons.graphic_eq_rounded,
                title: _t('Voice Recognition Profile', 'ملف تعريف الصوت'),
                subtitle: _t('Train NOOR to recognize your voice', 'درب نور على التعرف على صوتك'),
                onTap: () => _showVoiceTraining(),
              ),

              // Response Speed
              _tile(
                icon: Icons.speed_rounded,
                title: _t('Response Speed', 'سرعة الاستجابة'),
                subtitle: _t('Current: $_responseSpeed', 'الحالية: $_responseSpeed'),
                onTap: () => _showSpeedPicker(),
              ),

              // Haptics
              _tile(
                icon: Icons.vibration_rounded,
                title: _t('Haptic Feedback', 'الاهتزاز'),
                subtitle: _t(
                  _hapticEnabled ? 'Subtle vibrations on actions' : 'Disabled',
                  _hapticEnabled ? 'اهتزازات خفيفة عند الإجراءات' : 'معطل',
                ),
                trailing: Switch(
                  value: _hapticEnabled,
                  onChanged: (v) {
                    setState(() => _hapticEnabled = v);
                    _save('haptic', v);
                    if (v) HapticFeedback.mediumImpact();
                  },
                  activeColor: AuraTheme.accentBlue,
                  activeTrackColor: AuraTheme.accentBlue.withOpacity(0.2),
                ),
              ),

              const SizedBox(height: 32),

              // ── CONNECTION ─────────────────────────────────────────────────
              _sectionHeader(_t('CONNECTION', 'الاتصال')),

              _tile(
                icon: Icons.lan_rounded,
                title: _t('Backend Server', 'خادم الذكاء'),
                subtitle: _serverUrl,
                onTap: () => _showUrlEditor(),
              ),

              const SizedBox(height: 32),

              // ── ASSET PORTFOLIO ────────────────────────────────────────────
              _sectionHeader(_t('ASSET PORTFOLIO', 'محفظة العقارات')),

              _tile(
                icon: Icons.business_rounded,
                title: _t('Active Leases', 'عقود الإيجار النشطة'),
                subtitle: _t('2 active contracts', 'عقدان نشطان'),
                onTap: () => _showSheet(
                  _t('Active Leases', 'عقود الإيجار النشطة'),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow(_t('Property 1', 'العقار ١'), _t('The Horizon Tower, West Bay', 'برج الأفق، الخليج الغربي')),
                      _infoRow(_t('Status', 'الحالة'), _t('Active — Ends Nov 2026', 'نشط — ينتهي نوفمبر ٢٠٢٦')),
                      const Divider(color: Colors.white12, height: 24),
                      _infoRow(_t('Property 2', 'العقار ٢'), _t('Marina Residences, Lusail', 'مساكن المارينا، لوسيل')),
                      _infoRow(_t('Status', 'الحالة'), _t('Active — Ends Jan 2028', 'نشط — ينتهي يناير ٢٠٢٨')),
                    ],
                  ),
                ),
              ),

              _tile(
                icon: Icons.receipt_long_rounded,
                title: _t('Payment Schedules', 'جداول الدفع'),
                subtitle: _t('Next: 15 April 2026 — 12,000 QAR', 'التالي: ١٥ أبريل ٢٠٢٦ — ١٢٬٠٠٠ ريال'),
                onTap: () => _showSheet(
                  _t('Payment Schedules', 'جداول الدفع'),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow(_t('Next Payment', 'الدفعة القادمة'), _t('15 April 2026', '١٥ أبريل ٢٠٢٦')),
                      _infoRow(_t('Amount', 'المبلغ'), _t('12,000 QAR', '١٢,٠٠٠ ريال')),
                      const Divider(color: Colors.white12, height: 24),
                      _infoRow(_t('Auto-Pay', 'الدفع التلقائي'), _t('Enabled (Visa •••• 4242)', 'مفعّل (فيزا •••• ٤٢٤٢)')),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── ACCOUNT ────────────────────────────────────────────────────
              _sectionHeader(_t('ACCOUNT & SECURITY', 'الحساب والأمان')),

              _tile(
                icon: Icons.person_outline_rounded,
                title: _t('Profile Details', 'الملف الشخصي'),
                subtitle: _t('NOOR Premium Elite Member', 'عضو النخبة المميزة في نور'),
                onTap: () => _showSheet(
                  _t('Profile', 'الملف الشخصي'),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow(_t('Name', 'الاسم'), _userName),
                      _infoRow(_t('Tier', 'الفئة'), _t('NOOR Premium Elite', 'نور النخبة المميزة')),
                      _infoRow(_t('QID Status', 'حالة القطرية'), _t('Verified ✓', 'تم التحقق ✓')),
                    ],
                  ),
                ),
              ),

              _tile(
                icon: Icons.security_rounded,
                title: _t('Biometric Access', 'الدخول البيومتري'),
                subtitle: _t('Face ID / Fingerprint', 'بصمة الوجه / الإصبع'),
                trailing: Switch(
                  value: true,
                  onChanged: (v) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_t('Configure biometrics in device settings.', 'عدّل إعدادات البيومتري في الجهاز.')),
                        backgroundColor: AuraTheme.accentBlue.withOpacity(0.8),
                      ),
                    );
                  },
                  activeColor: AuraTheme.accentBlue,
                  activeTrackColor: AuraTheme.accentBlue.withOpacity(0.2),
                ),
              ),

              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  label: Text(_t('Sign Out', 'تسجيل الخروج')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent.withOpacity(0.8),
                    side: BorderSide(color: Colors.redAccent.withOpacity(0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _logout,
                ),
              ),

              const SizedBox(height: 48),
              Center(
                child: Opacity(
                  opacity: 0.25,
                  child: Column(
                    children: [
                      Text(_t('NOOR CORE v4.2.0', 'نور الأساس v4.2.0'),
                          style: const TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 2)),
                      const SizedBox(height: 4),
                      const Text('SYNIC INTELLIGENCE SYSTEMS',
                          style: TextStyle(color: AuraTheme.textPrimary, fontSize: 8, letterSpacing: 1)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AuraTheme.textSecondary),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AuraTheme.solidDecoration(radius: 16, shadow: false),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(title, style: const TextStyle(color: AuraTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: AuraTheme.textSecondary, fontSize: 12)),
        trailing: trailing ??
            (onTap != null
                ? const Icon(Icons.arrow_forward_ios_rounded, color: AuraTheme.textSecondary, size: 14)
                : null),
      ),
    );
  }

  Widget _langChip(String code, String label) {
    final selected = _language == code;
    return GestureDetector(
      onTap: () {
        setState(() => _language = code);
        _save('language', code);
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AuraTheme.accentBlue : AuraTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? Colors.transparent : AuraTheme.borderLight),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : AuraTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AuraTheme.textSecondary, fontSize: 13)),
            Text(value,
                style: const TextStyle(
                    color: AuraTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      );

  void _showSheet(String title, Widget content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraTheme.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Directionality(
        textDirection: _language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AuraTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              content,
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuraTheme.accentBlue.withOpacity(0.1),
                    foregroundColor: AuraTheme.accentBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(_t('Close', 'إغلاق')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSpeedPicker() {
    final options = ['Instant', 'Balanced', 'Thoughtful'];
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraTheme.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t('Response Speed', 'سرعة الاستجابة'),
                style: const TextStyle(
                    color: AuraTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              _t('Instant = fastest, Thoughtful = more detailed',
                  'فوري = أسرع، متأمل = أكثر تفصيلاً'),
              style: const TextStyle(color: AuraTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 20),
            ...options.map((opt) => ListTile(
                  onTap: () {
                    setState(() => _responseSpeed = opt);
                    _save('response_speed', opt);
                    Navigator.pop(context);
                  },
                  title: Text(opt, style: const TextStyle(color: AuraTheme.textPrimary)),
                  trailing: _responseSpeed == opt
                      ? const Icon(Icons.check_circle_rounded, color: AuraTheme.accentBlue)
                      : null,
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showUrlEditor() {
    final controller = TextEditingController(text: _serverUrl);
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraTheme.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t('Backend Server URL', 'رابط الخادم'),
                style: const TextStyle(
                    color: AuraTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              _t('Change this if your IP or Ngrok URL has changed.',
                  'غيّر هذا إذا تغيّر عنوان IP أو Ngrok.'),
              style: const TextStyle(color: AuraTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: AuraTheme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'http://192.168.x.x:8000',
                hintStyle: TextStyle(color: AuraTheme.textSecondary.withOpacity(0.5)),
                filled: true,
                fillColor: AuraTheme.background,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AuraTheme.borderLight)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuraTheme.accentBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  final newUrl = controller.text.trim();
                  if (newUrl.isNotEmpty) {
                    setState(() => _serverUrl = newUrl);
                    _save('server_url', newUrl);
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_t('Restart the app to apply new server.', 'أعد تشغيل التطبيق لتفعيل الخادم الجديد.')),
                      backgroundColor: AuraTheme.accentBlue.withOpacity(0.8),
                    ),
                  );
                },
                child: Text(_t('Save & Reconnect', 'حفظ وإعادة الاتصال')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVoiceTraining() {
    int step = 0;
    final phrases = [
      _t('Hi NOOR, it is me.', 'يا نور، هذا أنا.'),
      _t('My name is $_userName.', 'اسمي هو $_userName.'),
      _t('Show me properties in West Bay.', 'أرني العقارات في الخليج الغربي.'),
      _t('Navigate to my apartment.', 'وجهني إلى شقتي.'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AuraTheme.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mic_none_rounded, color: AuraTheme.accentBlue, size: 48),
              const SizedBox(height: 24),
              Text(_t('Voice Training', 'تدريب الصوت'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AuraTheme.textPrimary)),
              const SizedBox(height: 12),
              Text(
                _t('Speak the phrase below clearly into your microphone.', 'انطق العبارة أدناه بوضوح في الميكروفون.'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AuraTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 40),
              
              if (step < phrases.length) ...[
                Text(phrases[step], style: const TextStyle(fontSize: 18, color: AuraTheme.accentBlue, fontWeight: FontWeight.w600)),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuraTheme.accentBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  ),
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    setModalState(() => step++);
                    if (step == phrases.length) {
                       Future.delayed(const Duration(seconds: 1), () => Navigator.pop(context));
                    }
                  },
                  child: Text(_t('RECORD PHASE', 'تسجيل المرحلة')),
                ),
              ] else ...[
                 const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 48),
                 const SizedBox(height: 16),
                 Text(_t('Identification Profile Locked', 'تم قفل ملف التعريف'), style: const TextStyle(color: Colors.greenAccent)),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AuraTheme.surface,
        title: Text(_t('Sign Out?', 'تسجيل الخروج؟'),
            style: const TextStyle(color: AuraTheme.textPrimary)),
        content: Text(
            _t('You will need to log in again to access NOOR.',
                'ستحتاج لتسجيل الدخول مجدداً للوصول إلى نور.'),
            style: const TextStyle(color: AuraTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_t('Cancel', 'إلغاء'),
                style: const TextStyle(color: AuraTheme.textSecondary)),
          ),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(_t('Sign Out', 'تسجيل الخروج'),
                  style: const TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('aura_access_token');
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
