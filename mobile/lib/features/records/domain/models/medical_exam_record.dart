enum ExamType {
  papSmear('pap_smear', 'Papanicolau / Citología'),
  hpvTest('hpv_test', 'Prueba de VPH'),
  pelvicUltrasound('pelvic_ultrasound', 'Ultrasonido Pélvico'),
  breastUltrasound('breast_ultrasound', 'Ultrasonido Mamario'),
  mammogram('mammogram', 'Mamografía'),
  boneDensitometryDexa('bone_densitometry_dexa', 'Densitometría Ósea (DEXA)'),
  bloodPanel('blood_panel', 'Biometría / Perfil Bioquímico'),
  prenatalUltrasound('prenatal_ultrasound', 'Ultrasonido Obstétrico'),
  other('other', 'Otro Examen');

  final String value;
  final String displayName;
  const ExamType(this.value, this.displayName);

  static ExamType fromString(String val) {
    return ExamType.values.firstWhere(
      (e) => e.value == val,
      orElse: () => ExamType.other,
    );
  }
}

class AttachmentMetadata {
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final String storageKey;

  const AttachmentMetadata({
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.storageKey,
  });

  Map<String, dynamic> toJson() => {
        'file_name': fileName,
        'mime_type': mimeType,
        'size_bytes': sizeBytes,
        'storage_key': storageKey,
      };

  factory AttachmentMetadata.fromJson(Map<String, dynamic> json) {
    return AttachmentMetadata(
      fileName: json['file_name'] as String,
      mimeType: json['mime_type'] as String,
      sizeBytes: (json['size_bytes'] as num).toInt(),
      storageKey: json['storage_key'] as String,
    );
  }
}

class MedicalExamRecord {
  final String id;
  final String userId;
  final ExamType examType;
  final String title;
  final DateTime performedAt;
  final String? clinicOrLab;
  final String? notes;
  final AttachmentMetadata? attachment;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MedicalExamRecord({
    required this.id,
    required this.userId,
    required this.examType,
    required this.title,
    required this.performedAt,
    this.clinicOrLab,
    this.notes,
    this.attachment,
    required this.createdAt,
    required this.updatedAt,
  });

  MedicalExamRecord copyWith({
    String? id,
    String? userId,
    ExamType? examType,
    String? title,
    DateTime? performedAt,
    String? clinicOrLab,
    String? notes,
    AttachmentMetadata? attachment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicalExamRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      examType: examType ?? this.examType,
      title: title ?? this.title,
      performedAt: performedAt ?? this.performedAt,
      clinicOrLab: clinicOrLab ?? this.clinicOrLab,
      notes: notes ?? this.notes,
      attachment: attachment ?? this.attachment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'exam_type': examType.value,
        'title': title,
        'performed_at': performedAt.toIso8601String().split('T').first,
        'clinic_or_lab': clinicOrLab,
        'notes': notes,
        'attachment': attachment?.toJson(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory MedicalExamRecord.fromJson(Map<String, dynamic> json) {
    return MedicalExamRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      examType: ExamType.fromString(json['exam_type'] as String),
      title: json['title'] as String,
      performedAt: DateTime.parse(json['performed_at'] as String),
      clinicOrLab: json['clinic_or_lab'] as String?,
      notes: json['notes'] as String?,
      attachment: json['attachment'] != null
          ? AttachmentMetadata.fromJson(
              json['attachment'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }
}
