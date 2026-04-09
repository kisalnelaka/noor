import 'package:flutter/material.dart';
import 'package:noor/theme.dart';
import 'package:noor/widgets/trend_chart.dart';
import 'package:noor/widgets/property_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting = "Welcome back";
    if (hour < 12) greeting = "Good morning";
    else if (hour < 18) greeting = "Good afternoon";
    else greeting = "Good evening";

    // Mock featured properties for the dashboard
    final featuredProperties = [
      {
        'id': 'prop_1',
        'name': 'The Horizon Tower',
        'address': 'West Bay, Doha',
        'price': 'QAR 18,500 / month',
        'image_url': 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        'furnished_image_url': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        'tour_url': 'https://images.unsplash.com/photo-1557804506-669a67965ba0?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80'
      },
      {
        'id': 'prop_2',
        'name': 'Lusail Smart Hub',
        'address': 'Lusail, Doha',
        'price': 'QAR 12,000 / month',
        'image_url': 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      }
    ];

    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        title: const Text('NOOR ELITE', style: TextStyle(letterSpacing: 3.0, fontWeight: FontWeight.w800, fontSize: 14)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$greeting, Kisal.", style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text("Here is your real estate briefing for today.", style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            
            Text("MARKET PULSE", style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 12),
            const TrendChart(data: [2.8, 2.9, 3.1, 3.0, 3.4, 3.6], title: "Prime Yield Index"),
            
            const SizedBox(height: 32),
            Text("FEATURED ASSETS", style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 16),
            
            // Featured Properties List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: featuredProperties.length,
              separatorBuilder: (context, index) => const SizedBox(height: 24),
              itemBuilder: (context, index) {
                return PropertyCard(propertyData: featuredProperties[index]);
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
