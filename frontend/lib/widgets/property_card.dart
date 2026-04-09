import 'package:flutter/material.dart';
import '../theme.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui';
import 'pdf_viewer.dart';
import '../config.dart';
import '../screens/virtual_tour_screen.dart';
import '../services/websocket_service.dart';

class PropertyCard extends StatefulWidget {
  final Map<String, dynamic> propertyData;
  final WebSocketService? wsService; // 🧩 V4: Added for Document Query

  const PropertyCard({Key? key, required this.propertyData, this.wsService}) : super(key: key);

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  bool _showPois = false;
  bool _isFurnished = false; // 🪄 AI Staging State

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        decoration: AuraTheme.solidDecoration(radius: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🖼️ Premium Image Header
                Stack(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      child: Image.network(
                        _isFurnished 
                            ? (widget.propertyData['furnished_image_url'] ?? 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80')
                            : (widget.propertyData['image_url'] ?? 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'),
                        key: ValueKey(_isFurnished),
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // 🪄 Quick Actions Overlay
                    Positioned(
                      bottom: 12, left: 12,
                      child: Row(
                        children: [
                          _blurAction(
                            icon: _isFurnished ? Icons.auto_awesome_rounded : Icons.auto_awesome_outlined,
                            label: "STAGE",
                            active: _isFurnished,
                            onTap: () => setState(() => _isFurnished = !_isFurnished),
                          ),
                          const SizedBox(width: 8),
                          _blurAction(
                            icon: Icons.threed_rotation_rounded,
                            label: "360°",
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (context) => VirtualTourScreen(
                                  imageUrl: widget.propertyData['tour_url'] ?? 'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
                                  title: widget.propertyData['name'] ?? "Virtual Tour",
                                )
                              ));
                            },
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 12, right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AuraTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AuraTheme.borderLight),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0,2))
                          ]
                        ),
                        child: Text(
                          widget.propertyData['price']?.toString() ?? 'Request',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5, color: AuraTheme.textPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
                
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.propertyData['name'] ?? 'Premier Residence',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: AuraTheme.accentBlue, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            widget.propertyData['address'] ?? 'Doha, Qatar',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // 📊 Key Metrics Grid
                      _buildMetricsRow(context),
                      
                      const SizedBox(height: 20),
                      
                      // 💎 Aura Pro-Insights
                      _buildProInsights(),
                      
                      const SizedBox(height: 24),
                      
                      // ⚡ Premium Action Buttons (Voice is Primary)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.calendar_month_outlined, size: 18),
                              label: const Text("BOOK VIEWING"),
                              style: _btnStyle(context, AuraTheme.accentBlue),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("NOOR is scheduling your viewing for ${widget.propertyData['name']}...")),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.description_outlined, size: 18),
                              label: const Text("LEASE", style: TextStyle(color: AuraTheme.textPrimary)),
                              style: _btnStyle(context, AuraTheme.surface),
                              onPressed: () => _handleLeaseView(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.map_outlined, size: 18, color: AuraTheme.textSecondary),
                          label: const Text("VIEW ON MAP", style: TextStyle(color: AuraTheme.textSecondary)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AuraTheme.borderLight),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildMetricsRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _metric(Icons.square_foot_outlined, "${widget.propertyData['sqft'] ?? '2,400'} sqft"),
        _metric(Icons.king_bed_outlined, "${widget.propertyData['beds'] ?? '3'} Beds"),
        _metric(Icons.bathtub_outlined, "${widget.propertyData['baths'] ?? '2'} Baths"),
      ],
    );
  }

  Widget _buildProInsights() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuraTheme.accentBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AuraTheme.accentBlue.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _insightItem("INVESTMENT ROI", widget.propertyData['roi'] ?? "6.4%", Icons.trending_up, Colors.teal),
              const VerticalDivider(color: AuraTheme.borderLight),
              _insightItem("YIELD (ANNUAL)", widget.propertyData['yield'] ?? "QAR 180k", Icons.account_balance_wallet_outlined, AuraTheme.accentBlue),
            ],
          ),
          const Divider(height: 24, color: AuraTheme.borderLight),
          _buildPoiRow(),
        ],
      ),
    );
  }

  Widget _insightItem(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1, color: AuraTheme.textSecondary)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );

  }

  Widget _buildPoiRow() {
    return Row(
      children: [
        const Icon(Icons.stars_rounded, size: 14, color: Colors.amber),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            "POIs NEARBY: ${widget.propertyData['pois'] ?? 'Metro (3m), Place Vendôme (5m)'}",
            style: const TextStyle(fontSize: 10, color: AuraTheme.textSecondary, fontStyle: FontStyle.italic),
          ),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(40, 20)),
          child: const Text("VIEW ALL", style: TextStyle(fontSize: 9, color: AuraTheme.accentBlue)),
        ),
      ],
    );
  }

  Widget _metric(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AuraTheme.textSecondary, size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AuraTheme.textSecondary)),
      ],
    );
  }

  Widget _blurAction({required IconData icon, required String label, VoidCallback? onTap, bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: active ? AuraTheme.accentBlue.withOpacity(0.1) : AuraTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: active ? AuraTheme.accentBlue.withOpacity(0.6) : AuraTheme.borderLight),
            ),
            child: Row(
              children: [
                Icon(icon, size: 14, color: active ? AuraTheme.accentBlue : AuraTheme.textSecondary),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: active ? AuraTheme.accentBlue : AuraTheme.textSecondary)),
              ],
            ),
            ),
    );
  }

  ButtonStyle _btnStyle(BuildContext context, Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: color == AuraTheme.accentBlue ? Colors.white : AuraTheme.textPrimary,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
    );
  }

  Future<void> _handleLeaseView(BuildContext context) async {
    if (widget.propertyData['document_url'] != null) {
      try {
        final url = "${AuraConfig.baseUrl}/docs/${widget.propertyData['document_url']}";
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/temp_lease.pdf');
          await file.writeAsBytes(response.bodyBytes);
          if (context.mounted) {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => DocumentViewer(
                localPath: file.path, 
                title: widget.propertyData['name'] ?? "Lease Document",
                wsService: widget.wsService,
              )
            ));
          }
        }
      } catch (e) {
        print("Error: $e");
      }
    }
  }
}
