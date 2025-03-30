import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/screens/add_plant_screen.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import '../models/plant_model.dart';
import '../widgets/weather_widget.dart';
import '../widgets/plant_card_widget.dart';
import '../services/plant_service.dart';

class TodayScreen extends StatefulWidget {
  final String username;
  final GlobalKey<_TodayScreenState> _stateKey = GlobalKey<_TodayScreenState>();

  TodayScreen({super.key, required this.username});

  void refreshPlants() {
    _stateKey.currentState?._loadPlants();
  }

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  bool _isLoading = true;
  List<PlantModel> _myPlants = [];
  List<PlantModel> _plantsNeedingWater = [];
  String _greeting = '';

  String? _error;

  @override
  void initState() {
    super.initState();
    _setGreeting();
    _loadPlants();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good Morning';
    } else if (hour < 17) {
      _greeting = 'Good Afternoon';
    } else {
      _greeting = 'Good Evening';
    }
  }

  Future<void> _loadPlants() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final plants = await PlantService.getUserPlants();

      // Identify plants needing water
      final plantsNeedingWater =
          plants.where((plant) => plant.needsWatering()).toList();

      // Debug log for plants needing water
      debugPrint('Total plants: ${plants.length}');
      debugPrint('Plants needing water: ${plantsNeedingWater.length}');

      for (var plant in plantsNeedingWater) {
        final lastWatered =
            plant.wateringDates?.isNotEmpty == true
                ? DateFormat('MMM d').format(
                  plant.wateringDates!.reduce((a, b) => a.isAfter(b) ? a : b),
                )
                : 'never';
        debugPrint(
          'Plant needs water: ${plant.name} (Type: ${plant.plantType}, Last watered: $lastWatered)',
        );
      }

      if (mounted) {
        setState(() {
          _myPlants = plants;
          _plantsNeedingWater = plantsNeedingWater;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, MMMM d').format(DateTime.now());
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: RefreshIndicator(
        onRefresh: _loadPlants,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Greeting header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_greeting, ${widget.username}!',
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        today,
                        style: textTheme.titleMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Weather info card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: WeatherWidget(),
                ),
              ),

              // Plants needing attention
              if (_plantsNeedingWater.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    height: 140, // Reduced height for compact cards
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _plantsNeedingWater.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: PlantCard(
                            plant: _plantsNeedingWater[index],
                            needsWater: true,
                            onWatered:
                                () => {
                                  _waterPlant(_plantsNeedingWater[index]),
                                  _plantsNeedingWater.remove(
                                    _plantsNeedingWater[index],
                                  ),
                                  _loadPlants(),
                                },
                            isCompact:
                                true, // Use compact mode for horizontal list
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // My Plants
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'My Plants',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              // Navigate to add plant screen
                              // Navigator.push(context, MaterialPageRoute(...));
                            },
                            icon: Icon(Icons.add),
                            label: Text('Add'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                    ],
                  ),
                ),
              ),

              // Plants grid or loading indicator
              _isLoading
                  ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                  : _myPlants.isEmpty
                  ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.eco,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.onBackground.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text('No plants yet', style: textTheme.titleMedium),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  )
                  : SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return PlantCard(
                          plant: _myPlants[index],
                          needsWater: _plantsNeedingWater.contains(
                            _myPlants[index],
                          ),
                          onWatered:
                              () => {
                                _waterPlant(_myPlants[index]),
                                _plantsNeedingWater.remove(_myPlants[index]),
                                _loadPlants(), // Refresh plants after watering
                              },
                        );
                      }, childCount: _myPlants.length),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _waterPlant(PlantModel plant) async {
    try {
      await PlantService.waterPlant(plant.id!);

      // Refresh plants list
      _loadPlants();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${plant.name} has been watered!')),
        );
      }
    } catch (error) {
      debugPrint('Error recording watering: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to record watering. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
