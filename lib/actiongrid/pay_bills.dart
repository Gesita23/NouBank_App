import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

const Color primaryBlue = Color.fromARGB(255, 13, 71, 161);
const Color secondaryBlue = Color.fromARGB(255, 21, 101, 192);

// Bill Category Model
class BillCategory {
  final IconData icon;
  final String title;
  final String type;

  const BillCategory({
    required this.icon,
    required this.title,
    required this.type,
  });
}

class PayBillsPage extends StatefulWidget {
  const PayBillsPage({super.key});

  @override
  State<PayBillsPage> createState() => _PayBillsPageState();
}

class _PayBillsPageState extends State<PayBillsPage> {
  double _currentBalance = 0.0;
  // Account info from payment page
  String _accountType = 'Main Account';
  String _accountNumber = '****';

  // Bill categories - ALL USE SAME BLUE COLOR
  final List<BillCategory> billCategories = const [
    BillCategory(
      icon: Icons.electrical_services,
      title: 'Electricity',
      type: 'electricity',
    ),
    BillCategory(
      icon: Icons.water_drop,
      title: 'Water',
      type: 'water',
    ),
    BillCategory(
      icon: Icons.wifi,
      title: 'Internet',
      type: 'internet',
    ),
    BillCategory(
      icon: Icons.phone_android,
      title: 'Mobile',
      type: 'mobile',
    ),
    BillCategory(
      icon: Icons.tv,
      title: 'TV/Cable',
      type: 'tv',
    ),
    BillCategory(
      icon: Icons.local_gas_station,
      title: 'Gas',
      type: 'gas',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get account info from route arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _accountType = args['accountType'] ?? 'Main Account';
      _accountNumber = args['accountNumber'] ?? '****';
      if (args['accountBalance'] != null) {
        _currentBalance = args['accountBalance'];
      }
    }
  }

  Future<void> _loadBalance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _currentBalance = (doc.data()?['account_balance'] ?? 0.0).toDouble();
        });
      }
    }
  }

  void _navigateToBarcodeScanner(BillCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerPage(
          category: category,
          currentBalance: _currentBalance,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadBalance(); // Reload balance after successful payment
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Pay Bills',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryBlue,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildInfoCard(),
            const SizedBox(height: 20),
            _buildScanBarcodeCard(),
            const SizedBox(height: 24),
            _buildBillCategories(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryBlue, secondaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bill Payment',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pay your bills quickly and securely',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanBarcodeCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: InkWell(
          onTap: () {
            // Navigate to generic barcode scanner
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BarcodeScannerPage(
                  currentBalance: _currentBalance,
                ),
              ),
            ).then((result) {
              if (result == true) {
                _loadBalance();
              }
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    color: primaryBlue,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Scan Bill Barcode',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Scan your bill to pay instantly',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBillCategories() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bill Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.05,
            ),
            itemCount: billCategories.length,
            itemBuilder: (context, index) {
              final category = billCategories[index];
              return _buildCategoryCard(category);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BillCategory category) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      child: InkWell(
        onTap: () => _navigateToBarcodeScanner(category),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  category.icon,
                  color: primaryBlue,
                  size: 26,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                category.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Barcode Scanner Page
class BarcodeScannerPage extends StatefulWidget {
  final BillCategory? category;
  final double currentBalance;

  const BarcodeScannerPage({
    super.key,
    this.category,
    required this.currentBalance,
  });

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;
  String? _scannedCode;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture barcodeCapture) {
    if (_isProcessing) return;

    final barcode = barcodeCapture.barcodes.first;
    if (barcode.rawValue == null) return;

    setState(() {
      _isProcessing = true;
      _scannedCode = barcode.rawValue;
    });

    // Parse the barcode and show payment details
    _showPaymentDetails(_scannedCode!);
  }

  void _showPaymentDetails(String barcode) {
    // In a real app, you would decode the barcode to get bill details
    // For demo, we'll simulate bill data
    final billData = _parseBarcodeData(barcode);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (context) => BillPaymentSheet(
        billData: billData,
        currentBalance: widget.currentBalance,
        category: widget.category,
        onPaymentComplete: () {
          Navigator.pop(context); // Close sheet
          Navigator.pop(context, true); // Return to bills page with success
        },
        onCancel: () {
          setState(() {
            _isProcessing = false;
            _scannedCode = null;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Map<String, dynamic> _parseBarcodeData(String barcode) {
    // Simulate parsing barcode data
    // In a real app, this would decode the actual barcode format
    return {
      'barcode': barcode,
      'billNumber': 'BILL-${barcode.substring(0, 8)}',
      'amount': (50 + (barcode.length * 3.5)).toStringAsFixed(2),
      'dueDate': DateTime.now().add(const Duration(days: 7)),
      'provider': widget.category?.title ?? 'Utility Provider',
      'accountNumber': '****${barcode.substring(barcode.length - 4)}',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.category != null ? 'Scan ${widget.category!.title} Bill' : 'Scan Bill Barcode',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onBarcodeDetected,
          ),
          // Scanning overlay
          CustomPaint(
            painter: ScannerOverlay(),
            child: Container(),
          ),
          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Position the barcode within the frame',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Scanner Overlay Painter
class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.7,
      height: size.height * 0.3,
    );

    // Draw dark overlay with transparent center
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRRect(RRect.fromRectAndRadius(scanArea, const Radius.circular(16)))
        ..fillType = PathFillType.evenOdd,
      paint,
    );

    // Draw scan area border
    final borderPaint = Paint()
      ..color = primaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanArea, const Radius.circular(16)),
      borderPaint,
    );

    // Draw corner markers
    final cornerPaint = Paint()
      ..color = primaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final cornerLength = 30.0;

    // Top-left
    canvas.drawLine(scanArea.topLeft, scanArea.topLeft + Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(scanArea.topLeft, scanArea.topLeft + Offset(0, cornerLength), cornerPaint);

    // Top-right
    canvas.drawLine(scanArea.topRight, scanArea.topRight + Offset(-cornerLength, 0), cornerPaint);
    canvas.drawLine(scanArea.topRight, scanArea.topRight + Offset(0, cornerLength), cornerPaint);

    // Bottom-left
    canvas.drawLine(scanArea.bottomLeft, scanArea.bottomLeft + Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(scanArea.bottomLeft, scanArea.bottomLeft + Offset(0, -cornerLength), cornerPaint);

    // Bottom-right
    canvas.drawLine(scanArea.bottomRight, scanArea.bottomRight + Offset(-cornerLength, 0), cornerPaint);
    canvas.drawLine(scanArea.bottomRight, scanArea.bottomRight + Offset(0, -cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Bill Payment Sheet
class BillPaymentSheet extends StatefulWidget {
  final Map<String, dynamic> billData;
  final double currentBalance;
  final BillCategory? category;
  final VoidCallback onPaymentComplete;
  final VoidCallback onCancel;

  const BillPaymentSheet({
    super.key,
    required this.billData,
    required this.currentBalance,
    this.category,
    required this.onPaymentComplete,
    required this.onCancel,
  });

  @override
  State<BillPaymentSheet> createState() => _BillPaymentSheetState();
}

class _BillPaymentSheetState extends State<BillPaymentSheet> {
  bool _isProcessing = false;

  Future<void> _payBill() async {
    final amount = double.parse(widget.billData['amount']);

    if (amount > widget.currentBalance) {
      _showErrorDialog('Insufficient balance');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final batch = FirebaseFirestore.instance.batch();
      final timestamp = Timestamp.now();

      // Update user's balance and expenses
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      batch.update(userRef, {
        'account_balance': FieldValue.increment(-amount),
        'expenses': FieldValue.increment(amount),
      });

      // Create transaction
      final transactionRef = FirebaseFirestore.instance.collection('transactions').doc();
      batch.set(transactionRef, {
        'userId': user.uid,
        'type': 'debit',
        'amount': amount,
        'description': '${widget.billData['provider']} Bill Payment',
        'category': 'Bill Payment',
        'recipient': widget.billData['provider'],
        'note': 'Bill #${widget.billData['billNumber']}',
        'timestamp': timestamp,
        'billData': widget.billData,
      });

      await batch.commit();

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      _showErrorDialog('Payment failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 60),
            ),
            const SizedBox(height: 20),
            const Text(
              'Payment Successful!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Bill paid successfully',
              style: TextStyle(color: Colors.grey[700], fontSize: 15),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              widget.onPaymentComplete();
            },
            child: const Text(
              'Done',
              style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 10),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.parse(widget.billData['amount']);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              // Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.category?.icon ?? Icons.receipt_long,
                  color: primaryBlue,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                widget.billData['provider'],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Amount
              Text(
                'Rs ${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 30),
              // Bill Details
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Bill Number', widget.billData['billNumber']),
                    const Divider(height: 24),
                    _buildDetailRow('Account', widget.billData['accountNumber']),
                    const Divider(height: 24),
                    _buildDetailRow('Amount', 'Rs ${amount.toStringAsFixed(2)}'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isProcessing ? null : widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _payBill,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Pay Now',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}