import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Add this package for charts
import '../models/plant_model.dart';
import '../services/plant_service.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  List<PlantModel> _plants = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final plants = await PlantService.getUserPlants();

      setState(() {
        _plants = plants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Analytics'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text('Error: $_error'))
              : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCards(),
                      const SizedBox(height: 24),
                      _buildPlantTypeDistribution(),
                      const SizedBox(height: 24),
                      _buildGrowthTimeline(),
                      const SizedBox(height: 24),
                      _buildWateringStats(),
                      const SizedBox(height: 24),
                      _buildUpcomingHarvests(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildSummaryCards() {
    final totalPlants = _plants.length;
    final plantsNeedingWater =
        _plants.where((plant) {
          if (plant.wateringDates == null || plant.wateringDates!.isEmpty) {
            return true;
          }
          final lastWatered = plant.wateringDates!.reduce(
            (a, b) => a.isAfter(b) ? a : b,
          );
          return DateTime.now().difference(lastWatered).inDays >= 3;
        }).length;

    final readyToHarvest =
        _plants
            .where(
              (plant) => plant.expectedHarvestDate.isBefore(DateTime.now()),
            )
            .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Garden Overview',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.3, // Adaptive sizing
          crossAxisSpacing: 5,
          mainAxisSpacing: 5,
          children: [
            _buildStatCard(
              'Total Plants',
              totalPlants.toString(),
              Icons.eco,
              Colors.green,
            ),
            _buildStatCard(
              'Need Water',
              plantsNeedingWater.toString(),
              Icons.water_drop,
              Colors.blue,
            ),
            _buildStatCard(
              'Ready to Harvest',
              readyToHarvest.toString(),
              Icons.agriculture,
              Colors.amber,
            ),
            _buildStatCard(
              'Plant Types',
              _getPlantTypes().length.toString(),
              Icons.category,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.7), color],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.9), size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlantTypeDistribution() {
    // Group plants by type
    final Map<String, int> plantTypeCount = {};

    for (var plant in _plants) {
      if (plantTypeCount.containsKey(plant.plantType)) {
        plantTypeCount[plant.plantType] = plantTypeCount[plant.plantType]! + 1;
      } else {
        plantTypeCount[plant.plantType] = 1;
      }
    }

    // Sort by count
    final sortedTypes =
        plantTypeCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plant Distribution',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          height: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child:
              sortedTypes.isEmpty
                  ? const Center(child: Text("No plants to display"))
                  : PieChart(
                    PieChartData(
                      sections: _getPieChartSections(sortedTypes),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
        ),
        const SizedBox(height: 16),
        _buildPieChartLegend(sortedTypes),
      ],
    );
  }

  List<PieChartSectionData> _getPieChartSections(
    List<MapEntry<String, int>> types,
  ) {
    final List<Color> colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
      Colors.indigo,
      Colors.amber,
    ];

    return List.generate(types.length > 8 ? 8 : types.length, (index) {
      final type = types[index];
      final percentage = (type.value / _plants.length) * 100;

      return PieChartSectionData(
        value: type.value.toDouble(),
        title: '${percentage.toStringAsFixed(0)}%',
        color: colors[index % colors.length],
        radius: 90,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      );
    });
  }

  Widget _buildPieChartLegend(List<MapEntry<String, int>> types) {
    final List<Color> colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
      Colors.indigo,
      Colors.amber,
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: List.generate(
        types.length > 8 ? 8 : types.length,
        (index) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[index % colors.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${types[index].key} (${types[index].value})',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Growth Timeline',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          height: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child:
              _plants.isEmpty
                  ? const Center(child: Text("No plants to display"))
                  : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxGrowthDuration() * 1.2,
                      barGroups: _getBarGroups(),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}d',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 10,
                                ),
                              );
                            },
                            reservedSize: 30,
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 &&
                                  index < _getPlantTypes().length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    _getPlantTypes()[index],
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                            reservedSize: 30,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: math.max(
                          1.0,
                          _getMaxGrowthDuration() / 5,
                        ), // Never less than 1.0
                      ),
                    ),
                  ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Average Growth Duration by Plant Type (days)',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  List<BarChartGroupData> _getBarGroups() {
    final plantTypes = _getPlantTypes();

    return List.generate(plantTypes.length, (index) {
      final type = plantTypes[index];
      final typePlants = _plants.where((p) => p.plantType == type).toList();

      // Calculate average growth duration for this type
      double avgDuration = 0;
      for (var plant in typePlants) {
        avgDuration +=
            plant.expectedHarvestDate
                .difference(plant.sowingDate)
                .inDays
                .toDouble();
      }
      if (typePlants.isNotEmpty) {
        avgDuration /= typePlants.length;
      }

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: avgDuration,
            color: _getColorForPlantType(type),
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildWateringStats() {
    // Calculate watering stats
    int totalWaterings = 0;
    final Map<int, int> wateringsByWeekday = {
      1: 0,
      2: 0,
      3: 0,
      4: 0,
      5: 0,
      6: 0,
      7: 0,
    }; // Monday = 1

    for (var plant in _plants) {
      if (plant.wateringDates != null && plant.wateringDates!.isNotEmpty) {
        for (var date in plant.wateringDates!) {
          totalWaterings++;
          final weekday = date.weekday;
          wateringsByWeekday[weekday] = wateringsByWeekday[weekday]! + 1;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Watering Activity',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Total: $totalWaterings',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY:
                  wateringsByWeekday.values.isEmpty
                      ? 10
                      : wateringsByWeekday.values.reduce(
                            (a, b) => a > b ? a : b,
                          ) *
                          1.2,
              barGroups: _getWateringBarGroups(wateringsByWeekday),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                      final index = value.toInt();
                      if (index >= 0 && index < 7) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            weekdays[index],
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                    reservedSize: 30,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval:
                    wateringsByWeekday.values.isEmpty
                        ? 2.0
                        : math.max(
                          1.0,
                          wateringsByWeekday.values.reduce(
                                (a, b) => a > b ? a : b,
                              ) /
                              5,
                        ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Watering Activity by Day of Week',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  List<BarChartGroupData> _getWateringBarGroups(
    Map<int, int> wateringsByWeekday,
  ) {
    return List.generate(7, (index) {
      final weekday = index + 1; // 1-based (Monday = 1)
      final count = wateringsByWeekday[weekday] ?? 0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            color: Colors.blue.withOpacity(0.7),
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildUpcomingHarvests() {
    // Get plants that are coming up for harvest, sorted by date
    final upcomingHarvests =
        _plants
            .where((plant) => plant.expectedHarvestDate.isAfter(DateTime.now()))
            .toList()
          ..sort(
            (a, b) => a.expectedHarvestDate.compareTo(b.expectedHarvestDate),
          );

    // Take only the next 5 harvests
    final nextHarvests = upcomingHarvests.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Harvests',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (nextHarvests.isEmpty)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.grey.shade100,
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text("No upcoming harvests")),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: nextHarvests.length,
            itemBuilder: (context, index) {
              final plant = nextHarvests[index];
              final daysRemaining =
                  plant.expectedHarvestDate.difference(DateTime.now()).inDays;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _getColorForPlantType(
                            plant.plantType,
                          ).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            _getIconForPlantType(plant.plantType),
                            color: _getColorForPlantType(plant.plantType),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plant.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Harvest in $daysRemaining days',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  List<String> _getPlantTypes() {
    return _plants.map((plant) => plant.plantType).toSet().toList();
  }

  Color _getColorForPlantType(String type) {
    switch (type) {
      case 'Vegetable':
        return Colors.green;
      case 'Fruit':
        return Colors.red;
      case 'Herb':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForPlantType(String type) {
    switch (type) {
      case 'Vegetable':
        return Icons.eco;
      case 'Fruit':
        return Icons.local_florist;
      case 'Herb':
        return Icons.nature_people;
      default:
        return Icons.help_outline;
    }
  }

  int _getMaxGrowthDuration() {
    return _plants.isNotEmpty
        ? _plants
            .map(
              (plant) =>
                  plant.expectedHarvestDate.difference(plant.sowingDate).inDays,
            )
            .reduce((a, b) => a > b ? a : b)
        : 0;
  }
}
