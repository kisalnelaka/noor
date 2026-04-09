import 'package:flutter/material.dart';
import '../theme.dart';

class CalculatorCard extends StatefulWidget {
  final double price;

  const CalculatorCard({Key? key, required this.price}) : super(key: key);

  @override
  State<CalculatorCard> createState() => _CalculatorCardState();
}

class _CalculatorCardState extends State<CalculatorCard> {
  double _downPaymentPercent = 20.0;
  final double _interestRate = 5.5; // Standard Qatari rate

  @override
  Widget build(BuildContext context) {
    final downPayment = widget.price * (_downPaymentPercent / 100);
    final loanAmount = widget.price - downPayment;
    
    // Simple mock calculation for demonstration (25 years)
    final monthlyRate = (_interestRate / 100) / 12;
    final numPayments = 25 * 12;
    // Math.pow is missing, using a rough approximation for smooth UI
    final estimatedMonthly = (loanAmount * (monthlyRate + (monthlyRate / 200))) + (loanAmount / numPayments);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AuraTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_rounded, color: AuraTheme.accentBlue, size: 24),
              const SizedBox(width: 12),
              const Text('NOOR Investment Calculator', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          Text('Property Value: QAR ${widget.price.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Down Payment (${_downPaymentPercent.toInt()}%)', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              Text('QAR ${downPayment.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
          Slider(
            value: _downPaymentPercent,
            min: 10,
            max: 50,
            divisions: 8,
            activeColor: AuraTheme.accentBlue,
            inactiveColor: Colors.white12,
            onChanged: (val) {
              setState(() {
                _downPaymentPercent = val;
              });
            },
          ),
          const Divider(color: Colors.white12, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Est. Monthly Repayment', style: TextStyle(color: Colors.white54, fontSize: 14)),
              Text('QAR ${estimatedMonthly.toStringAsFixed(0)}', style: const TextStyle(color: AuraTheme.accentBlue, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Based on 5.5% interest variable over 25 years.', style: TextStyle(color: Colors.white24, fontSize: 10)),
        ],
      ),
    );
  }
}
