class DiaryEntryModel {
  final int? id;
  final int plantId;
  final double? height;
  final String? notes;
  final String? imageUrl;
  final DateTime? date;

  DiaryEntryModel({
    this.id,
    required this.plantId,
    this.height,
    this.notes,
    this.imageUrl,
    this.date,
  });

  factory DiaryEntryModel.fromJson(Map<String, dynamic> json) {
    return DiaryEntryModel(
      id: json['id'],
      plantId: json['plant_id'],
      height: json['height'] != null ? json['height'].toDouble() : null,
      notes: json['notes'],
      imageUrl: json['image_url'],
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plant_id': plantId,
      'height': height,
      'notes': notes,
      'image_url': imageUrl,
      'date': date?.toIso8601String(),
    };
  }

  DiaryEntryModel copyWith({
    int? id,
    int? plantId,
    double? height,
    String? notes,
    String? imageUrl,
    DateTime? date,
  }) {
    return DiaryEntryModel(
      id: id ?? this.id,
      plantId: plantId ?? this.plantId,
      height: height ?? this.height,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      date: date ?? this.date,
    );
  }
}
