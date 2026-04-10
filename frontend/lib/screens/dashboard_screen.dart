import 'package:flutter/material.dart';
import 'package:noor/theme.dart';
import 'package:noor/widgets/trend_chart.dart';
import 'package:noor/widgets/property_card.dart';
import 'package:noor/services/data_service.dart';
import 'package:noor/services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _dataService = DataService();
  final _authService = AuthService();
  List<Map<String, dynamic>> _featuredProperties = [];
  String _userName = "User";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // 🧩 Fetch identity from local storage first to prevent 'User' flicker
    final storedName = await _authService.getFullName();
    if (storedName != null) {
      setState(() { _userName = storedName; });
    }

    final results = await Future.wait([
      _dataService.getFeaturedProperties(),
      _authService.getFullName(),
    ]);
    
    setState(() {
      _featuredProperties = results[0] as List<Map<String, dynamic>>;
      _userName = (results[1] as String?) ?? "NOOR Member";
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting = "Welcome back";
    if (hour < 12) greeting = "Good morning";
    else if (hour < 18) greeting = "Good afternoon";
    else greeting = "Good evening";

    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        title: const Text('NOOR ELITE', style: TextStyle(letterSpacing: 3.0, fontWeight: FontWeight.w800, fontSize: 14)),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AuraTheme.accentBlue,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$greeting, $_userName.", style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text("Here is your real estate briefing for today.", style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 32),
              
              Text("MARKET PULSE", style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 12),
              const TrendChart(data: [2.8, 2.9, 3.1, 3.0, 3.4, 3.6], title: "Prime Yield Index"),
              
              const SizedBox(height: 32),
              Text("FEATURED ASSETS", style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 16),
              
              if (_isLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(color: AuraTheme.accentBlue, strokeWidth: 2),
                ))
              else if (_featuredProperties.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text("Connecting to real-time asset database...", style: TextStyle(color: AuraTheme.textSecondary)),
                ))
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _featuredProperties.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 24),
                  itemBuilder: (context, index) {
                    return PropertyCard(propertyData: _featuredProperties[index]);
                  },
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
