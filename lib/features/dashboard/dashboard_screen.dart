import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../settings/settings_controller.dart';
import '../../core/database/database_helper.dart';
import '../../core/sync/sync_engine.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../expenses/expense_screen.dart';
import '../flocks/widgets/flock_form_sheet.dart';
import '../logs/daily_log_screen.dart';
import '../reports/report_screen.dart';
import '../sales/egg_sale_screen.dart';
import '../settings/settings_screen.dart';
import 'package:dave_farm/l10n/app_localizations.dart';

class DashboardScreen extends StatefulWidget {
  final SettingsController settingsController;

  const DashboardScreen({super.key, required this.settingsController});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    SyncEngine.instance.start();
    _pages = [
      _HomeTab(settingsController: widget.settingsController),
      const DailyLogScreen(),
      const EggSaleScreen(),
      const ExpenseScreen(),
    ];
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
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.dashboard_rounded),
              label: AppLocalizations.of(context)!.navDashboard),
          NavigationDestination(
              icon: const Icon(Icons.edit_note_rounded),
              label: AppLocalizations.of(context)!.navLogs),
          NavigationDestination(
              icon: const Icon(Icons.sell_rounded),
              label: AppLocalizations.of(context)!.navSales),
          NavigationDestination(
              icon: const Icon(Icons.receipt_long_rounded),
              label: AppLocalizations.of(context)!.navExpenses),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportScreen()),
              ),
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: Text(AppLocalizations.of(context)!.labelReport),
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home Tab — Analytics Dashboard
// ─────────────────────────────────────────────────────────────────────────────

class _HomeTab extends StatefulWidget {
  final SettingsController settingsController;
  const _HomeTab({required this.settingsController});

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

  // New 30-day metrics
  int _totalEggsGood30 = 0;
  int _totalEggsBroken30 = 0;
  int _totalEggsDamaged30 = 0;
  double _totalSales30 = 0;
  double _totalExpenses30 = 0;
  int _mortalityCount30 = 0;

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
      db.getEggBreakdown(start30, now),
      db.getTotalSales(start30, now),
      db.getTotalExpenses(start30, now),
      db.getMortalityCount(start30, now),
    ]);

    if (mounted) {
      final breakdown = results[6] as Map<String, int>;
      setState(() {
        _todayEggs = results[0] as int;
        _totalBirds = results[1] as int;
        _netProfit = (results[2] as num).toDouble();
        _costPerEgg = (results[3] as num).toDouble();
        _eggTrend = results[4] as List<Map<String, dynamic>>;
        _profitTrend = results[5] as List<Map<String, dynamic>>;
        _totalEggsGood30 = breakdown['good']!;
        _totalEggsBroken30 = breakdown['broken']!;
        _totalEggsDamaged30 = breakdown['damaged']!;
        _totalSales30 = (results[7] as num).toDouble();
        _totalExpenses30 = (results[8] as num).toDouble();
        _mortalityCount30 = results[9] as int;
        _layingPct = _totalBirds > 0 ? (_todayEggs / _totalBirds * 100) : 0;
        _loading = false;
      });
    }
  }

  void _openAddFlock() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FlockFormSheet(
        onSaved: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: AppLocalizations.of(context)!.titleAddFlock,
            onPressed: _openAddFlock,
          ),
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: AppLocalizations.of(context)!.labelSyncNow,
            onPressed: () async {
              await SyncEngine.instance.syncNow();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.msgSyncComplete)));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: AppLocalizations.of(context)!.titleSettings,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    controller: widget.settingsController,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _totalBirds == 0 && !_loading
                ? _EmptyFlockState(onAdd: _openAddFlock)
                : ListView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  _SectionHeader(AppLocalizations.of(context)!.labelTodayPerformance),
                  MetricCard(
                    label: AppLocalizations.of(context)!.labelLayingPercentage,
                    value: '${_layingPct.toStringAsFixed(1)}%',
                    icon: Icons.percent_rounded,
                    color: const Color(0xFF43A047),
                    subtitle: '$_todayEggs ${AppLocalizations.of(context)!.fieldGoodEggs.toLowerCase()} / $_totalBirds ${AppLocalizations.of(context)!.fieldDeadBirds.split(' ')[1].toLowerCase()}',
                  ),
                  MetricCard(
                    label: AppLocalizations.of(context)!.labelCostPerEgg,
                    value: 'ETB ${_costPerEgg.toStringAsFixed(2)}',
                    icon: Icons.calculate_rounded,
                    color: const Color(0xFFFFA000),
                  ),
                  MetricCard(
                    label: AppLocalizations.of(context)!.labelNetProfit,
                    value: 'ETB ${_netProfit.toStringAsFixed(2)}',
                    icon: Icons.trending_up_rounded,
                    color: _netProfit >= 0
                        ? const Color(0xFF43A047)
                        : Colors.redAccent,
                  ),
                  MetricCard(
                    label: AppLocalizations.of(context)!.labelCurrentBirds,
                    value: '$_totalBirds',
                    icon: Icons.pets_rounded,
                    color: Colors.white70,
                  ),
                  const SizedBox(height: 16),

                  _SectionHeader(AppLocalizations.of(context)!.labelLast30Days),
                  
                  // Financial Summary row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SmallMetricCard(
                            label: AppLocalizations.of(context)!.labelTotalSales,
                            value: 'ETB ${_totalSales30.toStringAsFixed(0)}',
                            color: const Color(0xFF43A047),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SmallMetricCard(
                            label: AppLocalizations.of(context)!.labelTotalExpenses,
                            value: 'ETB ${_totalExpenses30.toStringAsFixed(0)}',
                            color: Colors.orangeAccent,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Production Breakdown card
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.labelTotalProduction,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _BreakdownItem(
                                label: AppLocalizations.of(context)!.labelGood,
                                value: _totalEggsGood30,
                                color: Colors.greenAccent,
                              ),
                              _BreakdownItem(
                                label: AppLocalizations.of(context)!.labelBroken,
                                value: _totalEggsBroken30,
                                color: Colors.orangeAccent,
                              ),
                              _BreakdownItem(
                                label: AppLocalizations.of(context)!.labelDamaged,
                                value: _totalEggsDamaged30,
                                color: Colors.deepOrangeAccent,
                              ),
                              _BreakdownItem(
                                label: AppLocalizations.of(context)!.labelDead,
                                value: _mortalityCount30,
                                color: Colors.redAccent,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Egg production chart
                  if (_eggTrend.isNotEmpty) ...[
                    _SectionHeader(AppLocalizations.of(context)!.labelEggProduction),
                    _EggLineChart(data: _eggTrend),
                  ],

                  // Net profit chart
                  if (_profitTrend.isNotEmpty) ...[
                    _SectionHeader(AppLocalizations.of(context)!.labelNetProfitChart),
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

class _EmptyFlockState extends StatelessWidget {
  const _EmptyFlockState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.egg_outlined, size: 80, color: Colors.white24),
            ),
            const SizedBox(height: 24),
            Text(AppLocalizations.of(context)!.labelTotalFlocks.replaceAll('Active', 'No'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            const Text('To see analytics, you first need to register your flock.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, height: 1.5)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.titleAddFlock),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            ),
          ],
        ),
      ),
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
        padding: const EdgeInsets.only(top: 16, right: 24, bottom: 8, left: 8),
        child: SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => Colors.blueGrey.withOpacity(0.8),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((s) {
                      return LineTooltipItem(
                        '${s.y.toInt()} eggs',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    }).toList();
                  },
                ),
              ),
              minX: 0,
              maxX: (data.length - 1).toDouble(),
              minY: 0,
              maxY: maxY * 1.2,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      if (value == meta.max || value == meta.min) return const SizedBox();
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
        padding: const EdgeInsets.only(top: 16, right: 24, bottom: 8, left: 8),
        child: SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.blueGrey.withOpacity(0.8),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final isNegative = data[groupIndex]['net_profit'] < 0;
                    return BarTooltipItem(
                      '${isNegative ? '-' : ''}ETB ${rod.toY.toInt()}',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ),
              maxY: maxY * 1.2,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value == meta.max || value == meta.min) return const SizedBox();
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              barGroups: groups,
            ),
          ),
        ),
      ),
    );
  }
}
class _SmallMetricCard extends StatelessWidget {
  const _SmallMetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownItem extends StatelessWidget {
  const _BreakdownItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color.withOpacity(0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
