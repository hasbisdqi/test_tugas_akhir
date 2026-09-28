class CropModel {
  final int? id;
  final int userId;
  final String name;
  final String variety;
  final DateTime plantingDate;
  final DateTime? harvestDate;
  final double landAreaHa;
  final double expectedYieldTon;
  final String status; // 'growing', 'harvest_ready', 'harvested', 'diseased'
  final String? notes;
  final DateTime createdAt;

  CropModel({
    this.id,
    required this.userId,
    required this.name,
    required this.variety,
    required this.plantingDate,
    this.harvestDate,
    required this.landAreaHa,
    required this.expectedYieldTon,
    this.status = 'growing',
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'variety': variety,
      'planting_date': plantingDate.toIso8601String(),
      'harvest_date': harvestDate?.toIso8601String(),
      'land_area_ha': landAreaHa,
      'expected_yield_ton': expectedYieldTon,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CropModel.fromMap(Map<String, dynamic> map) {
    return CropModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int? ?? 1,
      name: map['name'] as String? ?? '',
      variety: map['variety'] as String? ?? '',
      plantingDate: map['planting_date'] != null
          ? DateTime.tryParse(map['planting_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      harvestDate: map['harvest_date'] != null
          ? DateTime.tryParse(map['harvest_date'].toString())
          : null,
      landAreaHa: (map['land_area_ha'] is num) ? (map['land_area_ha'] as num).toDouble() : 0.0,
      expectedYieldTon: (map['expected_yield_ton'] is num)
          ? (map['expected_yield_ton'] as num).toDouble()
          : 0.0,
      status: map['status'] as String? ?? 'growing',
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  CropModel copyWith({
    int? id,
    int? userId,
    String? name,
    String? variety,
    DateTime? plantingDate,
    DateTime? harvestDate,
    double? landAreaHa,
    double? expectedYieldTon,
    String? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return CropModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      variety: variety ?? this.variety,
      plantingDate: plantingDate ?? this.plantingDate,
      harvestDate: harvestDate ?? this.harvestDate,
      landAreaHa: landAreaHa ?? this.landAreaHa,
      expectedYieldTon: expectedYieldTon ?? this.expectedYieldTon,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
