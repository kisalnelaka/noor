import 'package:flutter/material.dart';
import 'package:noor/theme.dart';
import 'package:noor/screens/settings_screen.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        title: const Text('PORTFOLIO', style: TextStyle(letterSpacing: 3.0, fontWeight: FontWeight.w800, fontSize: 14)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AuraTheme.accentBlue.withOpacity(0.1),
                  child: const Text("KX", style: TextStyle(color: AuraTheme.accentBlue, fontWeight: FontWeight.bold, fontSize: 20)),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Kisal Executive", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20)),
                    const SizedBox(height: 4),
                    const Text("demo@noor.qa", style: TextStyle(color: AuraTheme.textSecondary, fontSize: 14)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Executive Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: AuraTheme.solidDecoration(radius: 12, shadow: false).copyWith(
                color: AuraTheme.accentPastelPurple.withOpacity(0.05),
                border: Border.all(color: AuraTheme.accentPastelPurple.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium_rounded, color: AuraTheme.accentPastelPurple, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(child: Text("Elite Membership Active", style: TextStyle(fontWeight: FontWeight.w700, color: AuraTheme.accentPastelPurple, fontSize: 13))),
                  Text("Manage", style: TextStyle(color: AuraTheme.accentPastelPurple.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            Text("UPCOMING VIEWINGS", style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 16),
            _buildBookingCard("The Horizon Tower", "Tomorrow at 4:30 PM", "Confirmed"),
            const SizedBox(height: 12),
            _buildBookingCard("The Pearl Royal Palms Villa", "Thursday at 10:00 AM", "Pending"),

            const SizedBox(height: 40),
            Text("DOCUMENT VAULT", style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 16),
            _buildDocCard(Icons.article_rounded, "Horizon Tower Lease.pdf", "Active until Nov 2026"),
            const SizedBox(height: 12),
            _buildDocCard(Icons.verified_user_rounded, "Qatar ID", "Verified"),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(String title, String time, String status) {
    final isConfirmed = status == "Confirmed";
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AuraTheme.solidDecoration(radius: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isConfirmed ? AuraTheme.accentBlue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.calendar_month_rounded, color: isConfirmed ? AuraTheme.accentBlue : Colors.orange, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AuraTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(time, style: const TextStyle(color: AuraTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isConfirmed ? AuraTheme.accentBlue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isConfirmed ? AuraTheme.accentBlue : Colors.orange)),
          ),
        ],
      ),
    );
  }

  Widget _buildDocCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AuraTheme.solidDecoration(radius: 16, shadow: false),
      child: Row(
        children: [
          Icon(icon, color: AuraTheme.textSecondary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AuraTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AuraTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AuraTheme.textSecondary),
        ],
      ),
    );
  }
}
