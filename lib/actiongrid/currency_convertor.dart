import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Color primaryBlue = Color.fromARGB(255, 13, 71, 161);
Color secondaryBlue = Color.fromARGB(255, 21, 101, 192);

Map<String, double> _ratesFromUSD = {
  'USD': 1.0,
  'EUR': 0.92,
  'GBP': 0.79,
  'JPY': 149.50,
  'CAD': 1.36,
  'AUD': 1.53,
  'CHF': 0.88,
  'CNY': 7.24,
  'INR': 83.12,
  'MXN': 17.15,
  'BRL': 4.97,
  'KRW': 1325.00,
  'SGD': 1.34,
  'HKD': 7.82,
  'NOK': 10.55,
  'SEK': 10.42,
  'DKK': 6.88,
  'NZD': 1.63,
  'ZAR': 18.63,
  'THB': 35.20,
  'MUR': 45.50, 
};

List<String> _currencyCodes = [
  'USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY', 'INR', 'MXN',
  'BRL', 'KRW', 'SGD', 'HKD', 'NOK', 'SEK', 'DKK', 'NZD', 'ZAR', 'THB',
  'MUR',
];

double _convert(double amount, String from, String to) {
  final inUSD = amount / _ratesFromUSD[from]!;
  return inUSD * _ratesFromUSD[to]!;
}

class CurrencyConverterPage extends StatefulWidget {
  CurrencyConverterPage({super.key});

  @override
  State<CurrencyConverterPage> createState() => _CurrencyConverterPageState();
}

class _CurrencyConverterPageState extends State<CurrencyConverterPage> {
  final _amountController = TextEditingController(text: '1');
  String _fromCurrency = 'USD';
  String _toCurrency = 'EUR';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------
  // helpers
  // ------------------------------------------------------------------
  double get _inputAmount => double.tryParse(_amountController.text) ?? 0.0;

  double get _convertedAmount => _convert(_inputAmount, _fromCurrency, _toCurrency);

  double get _currentRate => _convert(1.0, _fromCurrency, _toCurrency);

  void _swap() {
    setState(() {
      final tmp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = tmp;
    });
  }

  Future<void> _pickCurrency(bool isFrom) async {
    final picked = await _showCurrencyPicker(context, isFrom ? _fromCurrency : _toCurrency);
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromCurrency = picked;
        } else {
          _toCurrency = picked;
        }
      });
    }
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Currency Converter',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryBlue,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── header icon ──
            SizedBox(height: 8),
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Icon(Icons.currency_exchange, color: primaryBlue, size: 36),
                ),
              ),
            ),
            SizedBox(height: 24),

            // ── FROM card ──
            _buildCurrencyCard(
              label: 'You have',
              currency: _fromCurrency,
              isFrom: true,
            ),

            SizedBox(height: 6),

            // ── SWAP button (centred between the two cards) ──
            Center(
              child: _SwapButton(onTap: _swap),
            ),

            SizedBox(height: 6),

            // ── TO card ──
            _buildCurrencyCard(
              label: 'You get',
              currency: _toCurrency,
              isFrom: false,
            ),

            SizedBox(height: 24),

            // ── live-rate pill ──
            _buildRateRow(),

            SizedBox(height: 28),

            // ── quick-amount chips ──
            _buildQuickAmounts(),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // FROM / TO card
  // ──────────────────────────────────────────────
  Widget _buildCurrencyCard({
    required String label,
    required String currency,
    required bool isFrom,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // label
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // amount field / display
              Expanded(
                child: isFrom
                    ? TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                        ],
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                    : Text(
                        _convertedAmount.toStringAsFixed(4),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
              ),
              // currency selector chip
              GestureDetector(
                onTap: () => _pickCurrency(isFrom),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Text(
                        currency,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: primaryBlue,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.expand_more, color: primaryBlue, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // rate line
  // ──────────────────────────────────────────────
  Widget _buildRateRow() {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.grey[500]),
            SizedBox(width: 6),
            Text(
              '1 $_fromCurrency = ${_currentRate.toStringAsFixed(4)} $_toCurrency',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // quick amounts
  // ──────────────────────────────────────────────
  Widget _buildQuickAmounts() {
    const amounts = [10, 50, 100, 500, 1000];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick amounts',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: amounts
              .map(
                (a) => GestureDetector(
                  onTap: () {
                    setState(() {
                      _amountController.text = a.toString();
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      'Rs $a',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

// ==========================================================================
// Swap button widget
// ==========================================================================
class _SwapButton extends StatelessWidget {
  final VoidCallback onTap;
  _SwapButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: primaryBlue,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.35),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(Icons.swap_vert, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ==========================================================================
// Currency picker — bottom sheet with search
// ==========================================================================
Future<String?> _showCurrencyPicker(BuildContext context, String current) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CurrencyPickerSheet(current: current),
  );
}

class _CurrencyPickerSheet extends StatefulWidget {
  final String current;
  _CurrencyPickerSheet({super.key, required this.current});

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  final _searchController = TextEditingController();
  List<String> _filtered = List.from(_currencyCodes);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    setState(() {
      _filtered = _currencyCodes
          .where((c) => c.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.55,
      child: Column(
        children: [
          // handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Select Currency',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 14),
          // search field
          TextField(
            controller: _searchController,
            onChanged: _filter,
            decoration: InputDecoration(
              hintText: 'Search…',
              prefixIcon: Icon(Icons.search, color: primaryBlue),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryBlue, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          SizedBox(height: 10),
          // list
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (ctx, i) {
                final code = _filtered[i];
                final isSelected = code == widget.current;
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? primaryBlue.withOpacity(0.1) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        code.substring(0, 1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? primaryBlue : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    code,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? primaryBlue : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    _currencyName(code),
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: primaryBlue)
                      : null,
                  onTap: () => Navigator.pop(ctx, code),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _currencyName(String code) {
  const names = {
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'JPY': 'Japanese Yen',
    'CAD': 'Canadian Dollar',
    'AUD': 'Australian Dollar',
    'CHF': 'Swiss Franc',
    'CNY': 'Chinese Yuan',
    'INR': 'Indian Rupee',
    'MXN': 'Mexican Peso',
    'BRL': 'Brazilian Real',
    'KRW': 'South Korean Won',
    'SGD': 'Singapore Dollar',
    'HKD': 'Hong Kong Dollar',
    'NOK': 'Norwegian Krone',
    'SEK': 'Swedish Krona',
    'DKK': 'Danish Krone',
    'NZD': 'New Zealand Dollar',
    'ZAR': 'South African Rand',
    'THB': 'Thai Baht',
    'MUR': 'Mauritian Rupee',
  };
  return names[code] ?? code;
}