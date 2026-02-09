import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

const Color primaryBlue = Color.fromARGB(255, 13, 71, 161);
const Color lightBlue = Color(0xFF2196F3); // Income color - lighter blue
const Color darkBlue = Color(0xFF0D47A1); // Expense color - darker blue
const Color accentBlue = Color(0xFF1976D2); // Medium blue for accents

class MonthlyStats {
  final String month;
  final double income;
  final double expense;

  MonthlyStats({
    required this.month,
    required this.income,
    required this.expense,
  });
}

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  // Calculate monthly statistics from transactions
  Future<List<MonthlyStats>> _calculateMonthlyStats(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .get();

    // Group transactions by month
    Map<String, MonthlyStats> monthlyData = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final timestamp = data['timestamp'] as Timestamp?;
      
      if (timestamp == null) continue;

      final date = timestamp.toDate();
      final monthKey = DateFormat('MMM yyyy').format(date);
      final amount = (data['amount'] ?? 0.0).toDouble();
      final type = data['type'] ?? 'debit';

      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = MonthlyStats(
          month: DateFormat('MMM').format(date),
          income: 0,
          expense: 0,
        );
      }

      if (type == 'credit') {
        monthlyData[monthKey] = MonthlyStats(
          month: monthlyData[monthKey]!.month,
          income: monthlyData[monthKey]!.income + amount,
          expense: monthlyData[monthKey]!.expense,
        );
      } else {
        monthlyData[monthKey] = MonthlyStats(
          month: monthlyData[monthKey]!.month,
          income: monthlyData[monthKey]!.income,
          expense: monthlyData[monthKey]!.expense + amount,
        );
      }
    }

    // Convert to list and sort by date (most recent last 6 months)
    final sortedEntries = monthlyData.entries.toList()
      ..sort((a, b) => DateFormat('MMM yyyy')
          .parse(a.key)
          .compareTo(DateFormat('MMM yyyy').parse(b.key)));

    // Take last 6 months
    return sortedEntries
        .map((e) => e.value)
        .toList()
        .reversed
        .take(6)
        .toList()
        .reversed
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Statistics'),
          backgroundColor: primaryBlue,
        ),
        body: const Center(
          child: Text('Please log in to view statistics'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Statistics',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryBlue,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        elevation: 0,
      ),
      body: FutureBuilder<List<MonthlyStats>>(
        future: _calculateMonthlyStats(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryBlue),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading statistics',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data ?? [];

          if (data.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No transaction data yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start making transactions to see statistics',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildPieChart(data),
                const SizedBox(height: 32),
                _buildBarChart(data),
                const SizedBox(height: 32),
                _buildSummaryCards(data),
              ],
            ),
          );
        },
      ),
    );
  }

  /// PIE CHART (Total Income vs Total Expense)
  Widget _buildPieChart(List<MonthlyStats> data) {
    final totalIncome = data.fold(0.0, (sum, item) => sum + item.income);
    final totalExpense = data.fold(0.0, (sum, item) => sum + item.expense);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Income vs Expenditure',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 220,
                child: totalIncome == 0 && totalExpense == 0
                    ? Center(
                        child: Text(
                          'No data available',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                    : PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 40,
                          sections: [
                            PieChartSectionData(
                              value: totalIncome,
                              title: 'Income\n\$${totalIncome.toStringAsFixed(0)}',
                              color: lightBlue,
                              radius: 60,
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            PieChartSectionData(
                              value: totalExpense,
                              title: 'Expense\n\$${totalExpense.toStringAsFixed(0)}',
                              color: darkBlue,
                              radius: 60,
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegendItem('Income', lightBlue, totalIncome),
                  _buildLegendItem('Expense', darkBlue, totalExpense),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, double amount) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// BAR CHART (Monthly breakdown)
  Widget _buildBarChart(List<MonthlyStats> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monthly Breakdown',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SizedBox(
            height: 280,
            child: data.isEmpty
                ? Center(
                    child: Text(
                      'No monthly data',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      barGroups: List.generate(data.length, (index) {
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: data[index].income,
                              color: lightBlue,
                              width: 12,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                            BarChartRodData(
                              toY: data[index].expense,
                              color: darkBlue,
                              width: 12,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '\$${value.toInt()}',
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 && value.toInt() < data.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    data[value.toInt()].month,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1000,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[300],
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: Colors.black87,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final type = rodIndex == 0 ? 'Income' : 'Expense';
                            return BarTooltipItem(
                              '$type\n\$${rod.toY.toStringAsFixed(2)}',
                              const TextStyle(color: Colors.white, fontSize: 12),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  /// SUMMARY CARDS
  Widget _buildSummaryCards(List<MonthlyStats> data) {
    final totalIncome = data.fold(0.0, (sum, item) => sum + item.income);
    final totalExpense = data.fold(0.0, (sum, item) => sum + item.expense);
    final netSavings = totalIncome - totalExpense;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Summary',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Net Balance',
                netSavings,
                netSavings >= 0 ? accentBlue : const Color(0xFF1565C0),
                netSavings >= 0 ? Icons.trending_up : Icons.trending_down,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Avg Income',
                data.isEmpty ? 0 : totalIncome / data.length,
                lightBlue,
                Icons.arrow_downward,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}