import 'package:flutter/material.dart';
import 'package:noor/screens/aura_home_screen.dart';
import 'package:noor/screens/dashboard_screen.dart';
import 'package:noor/screens/portfolio_screen.dart';
import 'package:noor/theme.dart';
import 'package:flutter/services.dart';
import 'package:noor/services/voice_interface_service.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onItemTapped(int index) {
    HapticFeedback.lightImpact();
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe to keep NOOR central
        children: const [
          DashboardScreen(),
          AuraHomeScreen(), // Center tab: The NOOR Brain
          PortfolioScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AuraTheme.borderLight, width: 1)),
        ),
        padding: const EdgeInsets.only(bottom: 24, top: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.dashboard_rounded, "Overview", 0),
            _buildNoorOrb(),
            _buildNavItem(Icons.account_circle_rounded, "Portfolio", 2),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AuraTheme.accentBlue : AuraTheme.textSecondary.withOpacity(0.5),
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AuraTheme.accentBlue : AuraTheme.textSecondary.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoorOrb() {
    final isSelected = _currentIndex == 1;
    final voiceService = VoiceInterfaceService();
    
    return GestureDetector(
      onTap: () {
        if (_currentIndex == 1) {
          voiceService.start(); // 🎙️ Trigger AI Recording session
        } else {
          _onItemTapped(1); // Navigate to AI
        }
      },
      child: ValueListenableBuilder<bool>(
        valueListenable: voiceService.isListening,
        builder: (context, listening, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: listening ? 88 : 80, // Enlarge during listening
            height: listening ? 88 : 80,
            decoration: BoxDecoration(
              color: isSelected ? AuraTheme.accentBlue : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? (listening ? Colors.white : Colors.transparent) : AuraTheme.borderLight,
                width: listening ? 4 : 2,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: AuraTheme.accentBlue.withOpacity(0.4),
                  blurRadius: listening ? 32 : 16,
                  offset: const Offset(0, 8),
                )
              ] : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Icon(
              listening ? Icons.mic_rounded : Icons.graphic_eq_rounded,
              color: isSelected ? Colors.white : AuraTheme.accentBlue,
              size: listening ? 40 : 36,
            ),
          );
        }
      ),
    );
  }
}
