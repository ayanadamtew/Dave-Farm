import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/sync/sync_engine.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../expenses/expense_screen.dart';
import '../flocks/flocks_screen.dart';
import '../logs/daily_log_screen.dart';
import '../reports/report_screen.dart';
import '../sales/egg_sale_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _HomeTab(),
    FlocksScreen(),
    DailyLogScreen(),
    EggSaleScreen(),
    ExpenseScreen(),
  ];

  @override
  void initState() {
    super.initState();
    SyncEngine.instance.start();
  }

  @override
  void dispose() {
    SyncEngine.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.egg_rounded), label: 'Flocks'),
          NavigationDestination(
              icon: Icon(Icons.edit_note_rounded), label: 'Daily Log'),
          NavigationDestination(
              icon: Icon(Icons.sell_rounded), label: 'Sales'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_rounded), label: 'Expenses'),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportScreen()),
              ),
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('Report'),
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home Tab — Analytics Dashboard
// ─────────────────────────────────────────────────────────────────────────────

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  bool _loading = true;

  // Metrics
  int _todayEggs = 0;
  int _totalBirds = 0;
  double _layingPct = 0;
  double _costPerEgg = 0;
  double _netProfit = 0;

  // Chart data
  List<Map<String, dynamic>> _eggTrend = [];
  List<Map<String, dynamic>> _profitTrend = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = DatabaseHelper.instance;
    final now = DateTime.now();
    final start30 = now.subtract(const Duration(days: 30));

    final results = await Future.wait([
      db.getTodayGoodEggs(),
      db.getTotalCurrentBirds(),
      db.getNetProfit(start30, now),
      db.getCostPerEgg(start30, now),
      db.getLast30DaysEggTotals(),
      db.getLast30DaysNetProfit(),
    ]);

    if (mounted) {
      setState(() {
        _todayEggs = results[0] as int;
        _totalBirds = results[1] as int;
        _netProfit = results[2] as double;
        _costPerEgg = results[3] as double;
        _eggTrend = results[4] as List<Map<String, dynamic>>;
        _profitTrend = results[5] as List<Map<String, dynamic>>;
        _layingPct = _totalBirds > 0 ? (_todayEggs / _totalBirds * 100) : 0;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dave Farm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Sync Now',
            onPressed: () async {
              await SyncEngine.instance.syncNow();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sync complete')));
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  _SectionHeader('Today\'s Performance'),
                  MetricCard(
                    label: 'Laying Percentage',
                    value: '${_layingPct.toStringAsFixed(1)}%',
                    icon: Icons.percent_rounded,
                    color: const Color(0xFF43A047),
                    subtitle: '$_todayEggs eggs / $_totalBirds birds',
                  ),
                  MetricCard(
                    label: 'Cost per Egg (30d)',
                    value: 'ETB ${_costPerEgg.toStringAsFixed(2)}',
                    icon: Icons.calculate_rounded,
                    color: const Color(0xFFFFA000),
                  ),
                  MetricCard(
                    label: 'Net Profit (30d)',
                    value: 'ETB ${_netProfit.toStringAsFixed(2)}',
                    icon: Icons.trending_up_rounded,
                    color: _netProfit >= 0
                        ? const Color(0xFF43A047)
                        : Colors.redAccent,
                  ),
                  MetricCard(
                    label: 'Total Birds',
                    value: '$_totalBirds',
                    icon: Icons.pets_rounded,
                    color: Colors.white70,
                  ),
                  const SizedBox(height: 8),

                  // Egg production chart
                  if (_eggTrend.isNotEmpty) ...[
                    _SectionHeader('Egg Production (30 days)'),
                    _EggLineChart(data: _eggTrend),
                  ],

                  // Net profit chart
                  if (_profitTrend.isNotEmpty) ...[
                    _SectionHeader('Net Profit (30 days)'),
                    _ProfitBarChart(data: _profitTrend),
                  ],
                ],
              ),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white60,
              letterSpacing: 0.8)),
    );
  }
}

// ─── Egg Line Chart ───────────────────────────────────────────────────────────

class _EggLineChart extends StatelessWidget {
  const _EggLineChart({required this.data});
  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context) {
    final spots = data.asMap().entries.map((e) {
      final total = (e.value['total_eggs'] as num?)?.toDouble() ?? 0;
      return FlSpot(e.key.toDouble(), total);
    }).toList();

    final maxY = spots.map((s) => s.y).fold(0.0, (a, b) => a > b ? a : b);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (data.length - 1).toDouble(),
              minY: 0,
              maxY: maxY * 1.2,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: const Color(0xFF43A047),
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF43A047).withOpacity(0.15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Net Profit Bar Chart ─────────────────────────────────────────────────────

class _ProfitBarChart extends StatelessWidget {
  const _ProfitBarChart({required this.data});
  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context) {
    final groups = data.asMap().entries.map((e) {
      final profit = (e.value['net_profit'] as num?)?.toDouble() ?? 0;
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: profit.abs(),
            color: profit >= 0
                ? const Color(0xFF43A047)
                : Colors.redAccent,
            width: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    final maxY = data
        .map((d) => ((d['net_profit'] as num?)?.abs() ?? 0).toDouble())
        .fold(0.0, (a, b) => a > b ? a : b);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: maxY * 1.2,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              barGroups: groups,
            ),
          ),
        ),
      ),
    );
  }
}
