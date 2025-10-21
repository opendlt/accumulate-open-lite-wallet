import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/services/storage/database_helper.dart';
import '../core/services/balance/balance_aggregation_service.dart';
import '../core/models/local_storage_models.dart';

class ChartWidget extends StatefulWidget {
  const ChartWidget({Key? key}) : super(key: key);

  @override
  State<ChartWidget> createState() => _ChartWidgetState();
}

class _ChartWidgetState extends State<ChartWidget> {
  bool _isLineChart = true;
  List<PriceData> _priceData = [];
  List<AccountBalancePercentage> _accountBalances = [];
  bool _isLoading = true;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final BalanceAggregationService _balanceService = BalanceAggregationService();

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    // First, show UI immediately with cached data
    if (mounted) {
      setState(() {
        _isLoading = false; // Show UI immediately
        // Initialize with minimal demo data for immediate display
        _priceData = _generateQuickDemoData();
        _accountBalances = [];
      });
    }

    // Load cached balance data first (fast)
    try {
      final balanceSummary = await _balanceService.getBalanceSummary();

      if (mounted) {
        setState(() {
          _accountBalances = balanceSummary.accountBalances;
        });
      }

      debugPrint('CHART WIDGET: Loaded ${_accountBalances.length} account balances');
      debugPrint('CHART WIDGET: Total balance: ${balanceSummary.totalBalance.toStringAsFixed(8)} ACME');

      // Load price data
      final existingPriceData = await _dbHelper.getPriceData();

      if (existingPriceData.isEmpty) {
        await _dbHelper.generateDummyPriceData();
      }

      // Load the price data only
      final priceData = await _dbHelper.getPriceData();

      if (mounted) {
        setState(() {
          _priceData = priceData;
          // Keep the real account balances from balance service
        });
      }
    } catch (e) {
      debugPrint('Info: Using demo chart data - $e');
      // Continue with demo data if database fails
    }
  }

  List<PriceData> _generateQuickDemoData() {
    final now = DateTime.now();
    return List.generate(7, (index) {
      return PriceData(
        date: now.subtract(Duration(days: 6 - index)),
        price: 0.50 + (index * 0.02) + (index % 2 * 0.01),
        tokenSymbol: 'ACME',
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 350,
          child: Column(
          children: [
            // Chart toggle header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isLineChart ? 'ACME Price Chart' : 'Portfolio Distribution',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ToggleButtons(
                  isSelected: [_isLineChart, !_isLineChart],
                  onPressed: (index) {
                    setState(() {
                      _isLineChart = index == 0;
                    });
                  },
                  children: const [
                    Tooltip(
                      message: 'Line Chart',
                      child: Icon(Icons.show_chart, size: 20),
                    ),
                    Tooltip(
                      message: 'Pie Chart',
                      child: Icon(Icons.pie_chart, size: 20),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Chart content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _isLineChart
                      ? _buildLineChart()
                      : _buildPieChart(),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    if (_priceData.isEmpty) {
      return const Center(
        child: Text(
          'No price data available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final spots = _priceData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.price);
    }).toList();

    final minY = _priceData.map((e) => e.price).reduce((a, b) => a < b ? a : b);
    final maxY = _priceData.map((e) => e.price).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${value.toStringAsFixed(3)}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (_priceData.length / 5).ceil().toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < _priceData.length) {
                  final date = _priceData[index].date;
                  return Text(
                    '${date.month}/${date.day}',
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: (_priceData.length - 1).toDouble(),
        minY: minY - padding,
        maxY: maxY + padding,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    if (_accountBalances.isEmpty) {
      return const Center(
        child: Text(
          'No wallet accounts found\nCreate accounts to see portfolio distribution',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final totalBalance = _accountBalances.fold<double>(
      0,
      (sum, account) => sum + account.acmeBalance,
    );

    if (totalBalance == 0) {
      return const Center(
        child: Text(
          'No ACME balance found\nAdd ACME to your accounts to see distribution',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal, Colors.amber, Colors.pink];

    final sections = _accountBalances.asMap().entries.map((entry) {
      final index = entry.key;
      final account = entry.value;

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: account.acmeBalance,
        title: '${account.percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total: ${totalBalance.toStringAsFixed(2)} ACME',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ..._accountBalances.asMap().entries.map((entry) {
                final index = entry.key;
                final account = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors[index % colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.accountName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${account.acmeBalance.toStringAsFixed(2)} ACME',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }
}