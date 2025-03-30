import 'DiaryEntryModel.dart';

class PlantModel {
  final int? id;
  final String name;
  final DateTime sowingDate;
  final String? substrate;
  final DateTime expectedHarvestDate;
  final String userId;
  final String plantType; // Add this field
  final List<DateTime>? wateringDates;
  final List<DiaryEntryModel>? diaryEntries;

  PlantModel({
    this.id,
    required this.name,
    required this.sowingDate,
    this.substrate,
    required this.expectedHarvestDate,
    required this.userId,
    String? plantType, // Add this parameter
    this.wateringDates,
    this.diaryEntries,
  }) : this.plantType = plantType ?? 'Vegetable'; // Default value

  factory PlantModel.fromJson(Map<String, dynamic> json) {
    // Parse watering dates if available
    List<DateTime>? wateringDates;
    if (json['watering_history'] != null) {
      wateringDates =
          (json['watering_history'] as List)
              .map((item) => DateTime.parse(item['watered_at']))
              .toList();
    }

    // Parse diary entries if available
    List<DiaryEntryModel>? diaryEntries;
    if (json['diary_entries'] != null) {
      diaryEntries =
          (json['diary_entries'] as List)
              .map((item) => DiaryEntryModel.fromJson(item))
              .toList();
    }

    // Handle ID properly - convert string to int if needed
    int? id;
    if (json['id'] != null) {
      if (json['id'] is int) {
        id = json['id'];
      } else if (json['id'] is String) {
        // Try to convert string to int
        id = int.tryParse(json['id']);
      }
    }

    return PlantModel(
      id: id,
      name: json['name'] ?? '',
      sowingDate:
          json['sowing_date'] != null
              ? DateTime.parse(json['sowing_date'])
              : DateTime.now(),
      substrate: json['substrate'] ?? '',
      expectedHarvestDate:
          json['expected_harvest_date'] != null
              ? DateTime.parse(json['expected_harvest_date'])
              : DateTime.now().add(const Duration(days: 60)),
      userId: json['user_id'] ?? '',
      wateringDates: wateringDates,
      diaryEntries: diaryEntries,
      plantType: json['plant_type'] ?? 'Vegetable',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sowing_date': sowingDate.toIso8601String().split('T')[0],
      'substrate': substrate,
      'expected_harvest_date':
          expectedHarvestDate.toIso8601String().split('T')[0],
      'user_id': userId,
      // The related entities are handled separately
    };
  }

  PlantModel copyWith({
    int? id,
    String? name,
    DateTime? sowingDate,
    String? substrate,
    DateTime? expectedHarvestDate,
    String? userId,
    List<DateTime>? wateringDates,
    List<DiaryEntryModel>? diaryEntries,
  }) {
    return PlantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sowingDate: sowingDate ?? this.sowingDate,
      substrate: substrate ?? this.substrate,
      expectedHarvestDate: expectedHarvestDate ?? this.expectedHarvestDate,
      userId: userId ?? this.userId,
      wateringDates: wateringDates ?? this.wateringDates,
      diaryEntries: diaryEntries ?? this.diaryEntries,
    );
  }

  /// Returns the last time the plant was watered, or null if never watered
  /// Returns the last time the plant was watered, or null if never watered
  DateTime? get lastWateredDate {
    if (wateringDates == null || wateringDates!.isEmpty) {
      return null;
    }

    // Sort dates and return the most recent one
    final dates = [...wateringDates!]..sort((a, b) => b.compareTo(a));
    return dates.first;
  }

  /// Returns true if the plant needs watering based on the last watering date.
  /// Default threshold is 3 days.
  bool needsWatering() {
    // If there's no watering history, it needs water
    if (wateringDates == null || wateringDates!.isEmpty) {
      return true;
    }

    // Get most recent watering date
    final lastWatered = wateringDates!.reduce((a, b) => a.isAfter(b) ? a : b);
    final daysSinceWatering = DateTime.now().difference(lastWatered).inDays;

    // Base watering frequency on plant type
    int wateringFrequency;
    switch (plantType.toLowerCase()) {
      case 'succulent':
        wateringFrequency = 14; // Every 2 weeks
        break;
      case 'herb':
        wateringFrequency = 2; // Every 2 days
        break;
      case 'vegetable':
      case 'fruit':
        wateringFrequency = 3; // Every 3 days
        break;
      case 'flower':
        wateringFrequency = 4; // Every 4 days
        break;
      case 'tree':
        wateringFrequency = 7; // Every week
        break;
      case 'indoor':
        wateringFrequency = 5; // Every 5 days
        break;
      default:
        wateringFrequency = 3; // Default: every 3 days
    }

    // Plant needs water if it's been longer than the watering frequency
    return daysSinceWatering >= wateringFrequency;
  }

  /// Records a new watering date
  PlantModel recordWatering([DateTime? date]) {
    final waterDate = date ?? DateTime.now();

    // Create a new list with existing dates plus the new one
    final List<DateTime> newWateringDates = [
      ...(wateringDates ?? []),
      waterDate,
    ];

    // Return a new plant model with the updated watering dates
    return copyWith(wateringDates: newWateringDates);
  }

  /// Returns the most recent diary entry, or null if there are no entries.
  DiaryEntryModel? get latestDiaryEntry {
    if (diaryEntries == null || diaryEntries!.isEmpty) {
      return null;
    }

    final sortedEntries =
        diaryEntries!.where((entry) => entry.date != null).toList()..sort(
          (a, b) =>
              (b.date ?? DateTime.now()).compareTo(a.date ?? DateTime.now()),
        );
    return sortedEntries.isNotEmpty ? sortedEntries.first : null;
  }

  /// Returns the current height of the plant based on the latest diary entry.
  double? get currentHeight {
    return latestDiaryEntry?.height;
  }

  /// Returns the number of days since the plant was sown.
  int get daysSinceSowing {
    return DateTime.now().difference(sowingDate).inDays;
  }

  /// Returns the number of days until the expected harvest date.
  int get daysUntilHarvest {
    return expectedHarvestDate.difference(DateTime.now()).inDays;
  }

  /// Returns the growth progress as a percentage of the total growing period.
  double get growthProgress {
    final totalGrowingPeriod =
        expectedHarvestDate.difference(sowingDate).inDays;
    final daysPassed = daysSinceSowing;

    if (totalGrowingPeriod <= 0) return 1.0; // Avoid division by zero

    final progress = daysPassed / totalGrowingPeriod;
    return progress.clamp(0.0, 1.0); // Ensure value is between 0 and 1
  }

  /// Returns how many days are left until the plant needs watering again
  int? get daysUntilNextWatering {
    final lastWatered = lastWateredDate;
    if (lastWatered == null) {
      return null; // Plant has never been watered
    }

    const wateringInterval = 3; // Default interval in days
    final daysSinceWatering = DateTime.now().difference(lastWatered).inDays;
    final daysLeft = wateringInterval - daysSinceWatering;

    return daysLeft > 0 ? daysLeft : 0;
  }

  @override
  String toString() {
    return 'PlantModel(id: $id, name: $name, sowingDate: $sowingDate)';
  }
}
