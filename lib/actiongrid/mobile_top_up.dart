import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color primaryBlue = Color.fromARGB(255, 13, 71, 161);

class _Carrier {
  final String name;
  final IconData icon;
  const _Carrier({required this.name, required this.icon});
}

const List<_Carrier> _carriers = [
  _Carrier(name: 'MyT', icon: Icons.wifi),
  _Carrier(name: 'Chilli', icon: Icons.cell_tower),
  _Carrier(name: 'Emtel', icon: Icons.network_cell),
];

const List<double> _presetAmounts = [50, 100, 200, 500, 1000];

class MobileTopUpPage extends StatefulWidget {
  const MobileTopUpPage({super.key});

  @override
  State<MobileTopUpPage> createState() => _MobileTopUpPageState();
}

class _MobileTopUpPageState extends State<MobileTopUpPage> {
  final _phoneController = TextEditingController();
  final _customAmountController = TextEditingController();

  int _selectedCarrierIndex = -1;
  double? _selectedAmount;
  bool _usingCustomAmount = false;
  bool _loading = false;

  double? get _finalAmount {
    if (_usingCustomAmount) {
      return double.tryParse(_customAmountController.text);
    }
    return _selectedAmount;
  }

  bool get _isValid {
    return !_loading &&
        _selectedCarrierIndex >= 0 &&
        _phoneController.text.trim().length >= 7 &&
        (_finalAmount ?? 0) > 0;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _customAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryBlue,
        title: const Text('Mobile Top-Up', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section('Select Carrier'),
            _carrierRow(),
            const SizedBox(height: 20),
            _section('Phone Number'),
            _phoneField(),
            const SizedBox(height: 20),
            _section('Select Amount'),
            _presetWrap(),
            const SizedBox(height: 12),
            _customAmountField(),
            const SizedBox(height: 24),
            if ((_finalAmount ?? 0) > 0) _summary(),
            const SizedBox(height: 16),
            _topUpButton(),
          ],
        ),
      ),
    );
  }

  Widget _section(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _carrierRow() {
    return Row(
      children: List.generate(_carriers.length, (i) {
        final selected = _selectedCarrierIndex == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedCarrierIndex = i),
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: selected ? primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? primaryBlue : Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Icon(
                    _carriers[i].icon,
                    color: selected ? Colors.white : primaryBlue,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _carriers[i].name,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _phoneField() {
    return _inputBox(
      TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d ]')),
          LengthLimitingTextInputFormatter(15),
        ],
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.phone, color: primaryBlue),
          hintText: 'Enter phone number',
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _presetWrap() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _presetAmounts.map((amount) {
        final selected = !_usingCustomAmount && _selectedAmount == amount;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedAmount = amount;
              _usingCustomAmount = false;
              _customAmountController.clear();
            });
          },
          child: Container(
            width: (MediaQuery.of(context).size.width - 40 - 32) / 5,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? primaryBlue : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: selected ? primaryBlue : Colors.grey[300]!),
            ),
            child: Center(
              child: Text(
                '\$${amount.toInt()}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _customAmountField() {
    return _inputBox(
      TextFormField(
        controller: _customAmountController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
        onChanged: (_) {
          setState(() {
            _usingCustomAmount = true;
            _selectedAmount = null;
          });
        },
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.attach_money, color: primaryBlue),
          hintText: 'Custom amount',
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _summary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryBlue.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_carriers[_selectedCarrierIndex].name} • ${_phoneController.text}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            '\$${(_finalAmount ?? 0).toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryBlue,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _topUpButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isValid ? _onTopUpTapped : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          disabledBackgroundColor: Colors.grey[400],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _loading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Top Up Now',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _inputBox(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: child,
    );
  }

  Future<void> _onTopUpTapped() async {
    setState(() => _loading = true);

    final user = FirebaseAuth.instance.currentUser;
    final amount = _finalAmount ?? 0;
    final carrier = _carriers[_selectedCarrierIndex];

    if (user == null) return;

    final ref =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final balance = (snap['balance'] as num).toDouble();

        if (balance < amount) {
          throw Exception('INSUFFICIENT');
        }

        tx.update(ref, {'balance': balance - amount});

        tx.set(
          ref.collection('transactions').doc(),
          {
            'type': 'mobile_topup',
            'amount': amount,
            'carrier': carrier.name,
            'phone': _phoneController.text,
            'createdAt': FieldValue.serverTimestamp(),
          },
        );
      });

      _successDialog(amount, carrier.name);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient balance or error')),
      );
    }

    setState(() => _loading = false);
  }

  void _successDialog(double amount, String carrier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 12),
            const Text('Top-Up Successful',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('\$${amount.toStringAsFixed(2)} sent via $carrier'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
