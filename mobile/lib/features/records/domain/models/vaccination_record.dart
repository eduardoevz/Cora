enum VaccineType {
  hpv('hpv', 'Virus del Papiloma Humano (VPH)'),
  tdap('tdap', 'Tdap (Tétanos, Difteria, Tosferina)'),
  rubellaMmr('rubella_mmr', 'Triple Viral (SRP)'),
  influenza('influenza', 'Influenza Estacional'),
  shinglesZoster('shingles_zoster', 'Herpes Zóster'),
  hepatitisB('hepatitis_b', 'Hepatitis B'),
  covid19('covid19', 'COVID-19'),
  other('other', 'Otra Vacuna');

  final String value;
  final String displayName;
  const VaccineType(this.value, this.displayName);

  static VaccineType fromString(String val) {
    return VaccineType.values.firstWhere(
      (v) => v.value == val,
      orElse: () => VaccineType.other,
    );
  }
}

class VaccinationRecord {
  final String id;
  final String userId;
  final VaccineType vaccineType;
  final int doseNumber;
  final DateTime administeredAt;
  final String? lotNumber;
  final String? administratorClinic;
  final String? notes;
  final DateTime createdAt;

  const VaccinationRecord({
    required this.id,
    required this.userId,
    required this.vaccineType,
    required this.doseNumber,
    required this.administeredAt,
    this.lotNumber,
    this.administratorClinic,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'vaccine_type': vaccineType.value,
        'dose_number': doseNumber,
        'administered_at': administeredAt.toIso8601String().split('T').first,
        'lot_number': lotNumber,
        'administrator_clinic': administratorClinic,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory VaccinationRecord.fromJson(Map<String, dynamic> json) {
    return VaccinationRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      vaccineType: VaccineType.fromString(json['vaccine_type'] as String),
      doseNumber: (json['dose_number'] as num).toInt(),
      administeredAt: DateTime.parse(json['administered_at'] as String),
      lotNumber: json['lot_number'] as String?,
      administratorClinic: json['administrator_clinic'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
