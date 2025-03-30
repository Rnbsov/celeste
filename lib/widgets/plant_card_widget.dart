import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import "package:myapp/models/plant_model.dart";
import "package:myapp/screens/plant_detail_screen.dart";

class PlantCard extends StatelessWidget {
  final PlantModel plant;
  final bool needsWater;
  final VoidCallback onWatered;
  final bool isCompact; // Add this new parameter for horizontal lists

  const PlantCard({
    super.key,
    required this.plant,
    this.needsWater = false,
    required this.onWatered,
    this.isCompact = false, // Default to full size
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final daysSinceSowing = DateTime.now().difference(plant.sowingDate).inDays;

    // Get plant type icon
    IconData plantIcon;
    Color plantColor;

    // Choose icon based on plant type
    switch (plant.plantType.toLowerCase()) {
      case 'vegetable':
        plantIcon = Icons.eco;
        plantColor = Colors.green;
        break;
      case 'fruit':
        plantIcon = Icons.spa;
        plantColor = Colors.orange;
        break;
      case 'herb':
        plantIcon = Icons.grass;
        plantColor = Colors.teal;
        break;
      case 'flower':
        plantIcon = Icons.local_florist;
        plantColor = Colors.purple;
        break;
      case 'succulent':
        plantIcon = Icons.filter_vintage;
        plantColor = Colors.lime;
        break;
      case 'tree':
        plantIcon = Icons.park;
        plantColor = Colors.brown;
        break;
      case 'indoor':
        plantIcon = Icons.home;
        plantColor = Colors.blueGrey;
        break;
      default:
        plantIcon = Icons.eco;
        plantColor = theme.colorScheme.primary;
    }

    // For compact mode, use a row layout with smaller image
    if (isCompact) {
      return Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side:
              needsWater
                  ? BorderSide(color: Colors.blue, width: 2)
                  : BorderSide.none,
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 250,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlantDetailScreen(plant: plant),
                  ),
                );
              },

              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: double.infinity,
                    color: plantColor.withOpacity(0.1),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(plantIcon, size: 40, color: plantColor),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: plantColor.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              plant.plantType,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  plant.name,
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (needsWater)
                                IconButton(
                                  icon: const Icon(
                                    Icons.water_drop,
                                    color: Colors.blue,
                                  ),
                                  onPressed: onWatered,
                                  tooltip: 'Water plant',
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  iconSize: 18,
                                ),
                            ],
                          ),
                          Text(
                            'Day $daysSinceSowing',
                            style: textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM d').format(plant.sowingDate),
                            style: textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onBackground.withOpacity(
                                0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Original card layout for grid view
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            needsWater
                ? BorderSide(color: Colors.blue, width: 2)
                : BorderSide.none,
      ),
      child: Material(
        // Add Material parent for InkWell
        color: Colors.transparent, // Keep card background

        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlantDetailScreen(plant: plant),
              ),
            );
          },
          child: Column(
            // The existing column goes here
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Plant image placeholder or actual image
              Stack(
                children: [
                  Container(
                    height: 120,
                    width: double.maxFinite,
                    decoration: BoxDecoration(
                      color: plantColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Icon(plantIcon, size: 48, color: plantColor),
                    ),
                  ),
                  // Plant type badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: plantColor.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        plant.plantType,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            plant.name,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (needsWater)
                          IconButton(
                            icon: const Icon(
                              Icons.water_drop,
                              color: Colors.blue,
                            ),
                            onPressed: onWatered,
                            tooltip: 'Water plant',
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            iconSize: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Day $daysSinceSowing', style: textTheme.bodySmall),
                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: theme.colorScheme.onBackground.withOpacity(
                            0.6,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d').format(plant.sowingDate),
                          style: textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onBackground.withOpacity(
                              0.6,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        if (plant.substrate != null &&
                            plant.substrate!.isNotEmpty)
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.terrain,
                                  size: 14,
                                  color: theme.colorScheme.onBackground
                                      .withOpacity(0.6),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    plant.substrate!,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onBackground
                                          .withOpacity(0.6),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
