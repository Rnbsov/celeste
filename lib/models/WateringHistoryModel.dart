class WateringHistoryModel {
  final int? id;
  final int plantId;
  final DateTime wateredAt;

  WateringHistoryModel({
    this.id,
    required this.plantId,
    required this.wateredAt,
  });

  /// Creates a WateringHistoryModel from a JSON object.
  factory WateringHistoryModel.fromJson(Map<String, dynamic> json) {
    return WateringHistoryModel(
      id: json['id'],
      plantId: json['plant_id'],
      wateredAt:
          json['watered_at'] is String
              ? DateTime.parse(json['watered_at'])
              : json['watered_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plant_id': plantId,
      'watered_at': wateredAt.toIso8601String(),
    };
  }

  WateringHistoryModel copyWith({int? id, int? plantId, DateTime? wateredAt}) {
    return WateringHistoryModel(
      id: id ?? this.id,
      plantId: plantId ?? this.plantId,
      wateredAt: wateredAt ?? this.wateredAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WateringHistoryModel &&
        other.id == id &&
        other.plantId == plantId &&
        other.wateredAt == wateredAt;
  }

  @override
  int get hashCode => id.hashCode ^ plantId.hashCode ^ wateredAt.hashCode;

  @override
  String toString() =>
      'WateringHistoryModel(id: $id, plantId: $plantId, wateredAt: $wateredAt)';
}
