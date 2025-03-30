import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/diary_entry_model.dart';
import '../models/plant_model.dart';
import '../services/plant_service.dart';

class PlantDetailScreen extends StatefulWidget {
  final PlantModel plant;

  const PlantDetailScreen({super.key, required this.plant});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  bool _isLoading = false;
  List<DateTime> _wateringHistory = [];
  String? _errorMessage;

  PlantModel get plant => widget.plant;

  List<DiaryEntryModel> _diaryEntries = [];
  bool _loadingDiary = false;

  Future<void> _loadDiaryEntries() async {
    setState(() {
      _loadingDiary = true;
    });

    try {
      final entries = await PlantService.getPlantDiaryEntries(
        int.parse(plant.id as String),
      );
      setState(() {
        _diaryEntries = entries;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load journal entries: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _loadingDiary = false;
      });
    }
  }

  // Add this to your initState() method
  @override
  void initState() {
    super.initState();
    _loadWateringHistory();
    _loadDiaryEntries(); // Add this line
  }

  Future<void> _loadWateringHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get the plant data including watering history
      final updatedPlant = await PlantService.getPlantById(plant.id!);
      if (updatedPlant.wateringDates != null) {
        setState(() {
          _wateringHistory = updatedPlant.wateringDates!;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load watering history: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _waterPlant() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await PlantService.waterPlant(plant.id!);

      // Refresh the watering history
      await _loadWateringHistory();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plant watered successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to water plant: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to water plant: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Get plant type info (similar to AddPlantScreen)
  Map<String, dynamic> get _plantTypeInfo {
    final plantTypes = [
      {
        'name': 'Vegetable',
        'icon': Icons.eco,
        'color': Colors.green,
        'description':
            'Edible plants grown for their leaves, stems, roots, or fruits.',
        'properties': {
          'Water needs': 'Medium',
          'Light': 'Full sun (6+ hours)',
          'Growth period': '2-4 months',
          'Beginner friendly': 'Yes',
        },
        'examples': ['Tomatoes', 'Carrots', 'Lettuce', 'Peppers', 'Beans'],
      },
      {
        'name': 'Fruit',
        'icon': Icons.spa,
        'color': Colors.orange,
        'description': 'Plants that produce sweet or tangy edible fruits.',
        'properties': {
          'Water needs': 'Medium to High',
          'Light': 'Full sun (6+ hours)',
          'Growth period': '3-12 months',
          'Beginner friendly': 'Moderate',
        },
        'examples': ['Strawberries', 'Blueberries', 'Melons', 'Citrus'],
      },
      {
        'name': 'Herb',
        'icon': Icons.grass,
        'color': Colors.teal,
        'description':
            'Aromatic plants used for flavoring, medicine, or fragrance.',
        'properties': {
          'Water needs': 'Low to Medium',
          'Light': 'Partial to full sun',
          'Growth period': '1-2 months',
          'Beginner friendly': 'Very',
        },
        'examples': ['Basil', 'Mint', 'Cilantro', 'Rosemary', 'Thyme'],
      },
      {
        'name': 'Flower',
        'icon': Icons.local_florist,
        'color': Colors.purple,
        'description': 'Ornamental plants grown for their colorful blooms.',
        'properties': {
          'Water needs': 'Varies by species',
          'Light': 'Full to partial sun',
          'Growth period': '1-6 months',
          'Beginner friendly': 'Moderate',
        },
        'examples': ['Roses', 'Sunflowers', 'Tulips', 'Marigolds', 'Zinnias'],
      },
      {
        'name': 'Succulent',
        'icon': Icons.filter_vintage,
        'color': Colors.lime,
        'description':
            'Plants with thick, fleshy tissues adapted to water storage.',
        'properties': {
          'Water needs': 'Very Low',
          'Light': 'Bright indirect light',
          'Growth period': 'Slow growing',
          'Beginner friendly': 'Very',
        },
        'examples': ['Aloe Vera', 'Echeveria', 'Jade Plant', 'Haworthia'],
      },
      {
        'name': 'Tree',
        'icon': Icons.park,
        'color': Colors.brown,
        'description': 'Woody perennial plants with an elongated stem/trunk.',
        'properties': {
          'Water needs': 'Medium',
          'Light': 'Full sun',
          'Growth period': 'Years',
          'Beginner friendly': 'No',
        },
        'examples': ['Apple', 'Lemon', 'Bonsai', 'Avocado', 'Fig'],
      },
      {
        'name': 'Indoor',
        'icon': Icons.home,
        'color': Colors.blueGrey,
        'description':
            'Plants well-suited for indoor environments with less light.',
        'properties': {
          'Water needs': 'Low to Medium',
          'Light': 'Indirect light',
          'Growth period': 'Varies',
          'Beginner friendly': 'Yes',
        },
        'examples': ['Peace Lily', 'Snake Plant', 'Pothos', 'Spider Plant'],
      },
    ];

    return plantTypes.firstWhere(
      (type) =>
          type['name'].toString().toLowerCase() ==
          plant.plantType.toLowerCase(),
      orElse: () => plantTypes[0],
    );
  }

  IconData _getPropertyIcon(String propertyName) {
    switch (propertyName.toLowerCase()) {
      case 'water needs':
        return Icons.water_drop;
      case 'light':
        return Icons.wb_sunny;
      case 'growth period':
        return Icons.calendar_today;
      case 'beginner friendly':
        return Icons.thumb_up;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final plantTypeInfo = _plantTypeInfo;
    final daysSinceSowing = DateTime.now().difference(plant.sowingDate).inDays;
    final daysToHarvest =
        plant.expectedHarvestDate.difference(DateTime.now()).inDays;
    final plantColor = plantTypeInfo['color'] as Color;

    // Choose icon based on plant type
    IconData plantIcon = plantTypeInfo['icon'] as IconData;

    return Scaffold(
      appBar: AppBar(
        title: Text(plant.name),
        backgroundColor: plantColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit screen
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Plant header with image and key info
                    Stack(
                      children: [
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: plantColor.withOpacity(0.2),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              plantIcon,
                              size: 100,
                              color: plantColor.withOpacity(0.7),
                            ),
                          ),
                        ),

                        // Plant type badge
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: plantColor.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              plant.plantType,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Plant name and substrate
                          Text(
                            plant.name,
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (plant.substrate != null &&
                              plant.substrate!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.terrain,
                                    size: 18,
                                    color: Colors.brown,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Substrate: ${plant.substrate}',
                                    style: textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 24),

                          // Key dates and progress
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  context,
                                  icon: Icons.calendar_today,
                                  title: 'Planted',
                                  value: DateFormat(
                                    'MMM d, y',
                                  ).format(plant.sowingDate),
                                  subtitle: '$daysSinceSowing days ago',
                                  color: plantColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildInfoCard(
                                  context,
                                  icon: Icons.event,
                                  title: 'Expected Harvest',
                                  value: DateFormat(
                                    'MMM d, y',
                                  ).format(plant.expectedHarvestDate),
                                  subtitle:
                                      daysToHarvest > 0
                                          ? 'In $daysToHarvest days'
                                          : 'Ready to harvest!',
                                  color: plantColor,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Plant type details
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: plantColor.withOpacity(0.3),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title with icon
                                  Row(
                                    children: [
                                      Icon(plantIcon, color: plantColor),
                                      const SizedBox(width: 8),
                                      Text(
                                        'About ${plant.plantType} Plants',
                                        style: textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Description
                                  Text(
                                    plantTypeInfo['description'] as String,
                                    style: textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 16),

                                  // Properties
                                  Text(
                                    'Growing Properties',
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: GridView.builder(
                                      physics: NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            childAspectRatio:
                                                1.8, // Smaller aspect ratio gives more height
                                            crossAxisSpacing: 10,
                                            mainAxisSpacing: 10,
                                          ),
                                      itemCount:
                                          (plantTypeInfo['properties']
                                                  as Map<String, dynamic>)
                                              .length,
                                      itemBuilder: (context, index) {
                                        final entry =
                                            (plantTypeInfo['properties']
                                                    as Map<String, dynamic>)
                                                .entries
                                                .elementAt(index);

                                        return Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            color: plantColor.withOpacity(0.08),
                                            border: Border.all(
                                              color: plantColor.withOpacity(
                                                0.2,
                                              ),
                                              width: 1,
                                            ),
                                          ),
                                          padding: EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    _getPropertyIcon(entry.key),
                                                    size: 16,
                                                    color: plantColor,
                                                  ),
                                                  SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      entry.key,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 12,
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade700,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 6),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 3,
                                                  horizontal: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: plantColor.withOpacity(
                                                    0.15,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '${entry.value}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                    color: plantColor
                                                        .withOpacity(0.9),
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  // Add this helper method in your _PlantDetailScreenState class
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Watering history
                          Text(
                            'Watering History',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (_wateringHistory.isEmpty)
                            Card(
                              elevation: 0,
                              color: Colors.grey.shade100,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Center(
                                  child: Text(
                                    'No watering records yet',
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Colors.blue.withOpacity(0.3),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Last watered: ${DateFormat('MMMM d, yyyy').format(_wateringHistory.first)}',
                                      style: textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Watering Dates',
                                      style: textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ..._wateringHistory
                                        .take(5) // Show only 5 most recent
                                        .map(
                                          (date) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.water_drop,
                                                  size: 16,
                                                  color: Colors.blue,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  DateFormat(
                                                    'MMMM d, yyyy',
                                                  ).format(date),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),

                                    if (_wateringHistory.length > 5)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          '+ ${_wateringHistory.length - 5} more entries',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _waterPlant,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.water_drop),
        label: const Text('Water Plant'),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
