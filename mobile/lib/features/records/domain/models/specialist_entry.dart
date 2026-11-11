enum SpecialtyType {
  gynecology('gynecology', 'Ginecología'),
  obstetrics('obstetrics', 'Obstetricia'),
  urology('urology', 'Urología'),
  endocrinology('endocrinology', 'Endocrinología'),
  generalMedicine('general_medicine', 'Medicina General / Familiar'),
  nutrition('nutrition', 'Nutrición'),
  psychology('psychology', 'Psicología / Salud Mental'),
  geriatrics('geriatrics', 'Geriatría'),
  other('other', 'Otra Especialidad');

  final String value;
  final String displayName;
  const SpecialtyType(this.value, this.displayName);

  static SpecialtyType fromString(String val) {
    return SpecialtyType.values.firstWhere(
      (s) => s.value == val,
      orElse: () => SpecialtyType.other,
    );
  }
}

class SpecialistEntry {
  final String id;
  final String userId;
  final String fullName;
  final SpecialtyType specialty;
  final String? clinicName;
  final String? phoneNumber;
  final String? email;
  final String? notes;
  final bool isFavorite;
  final DateTime createdAt;

  const SpecialistEntry({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.specialty,
    this.clinicName,
    this.phoneNumber,
    this.email,
    this.notes,
    this.isFavorite = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'full_name': fullName,
        'specialty': specialty.value,
        'clinic_name': clinicName,
        'phone_number': phoneNumber,
        'email': email,
        'notes': notes,
        'is_favorite': isFavorite,
        'created_at': createdAt.toIso8601String(),
      };

  factory SpecialistEntry.fromJson(Map<String, dynamic> json) {
    return SpecialistEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      fullName: json['full_name'] as String,
      specialty: SpecialtyType.fromString(json['specialty'] as String),
      clinicName: json['clinic_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String?,
      notes: json['notes'] as String?,
      isFavorite: json['is_favorite'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
