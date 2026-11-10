class VaginalBleedingRecord {
  final String id;
  final String userId;
  final DateTime observationDate;
  final int daysPriorAmenorrhea;
  final String flowIntensity;
  final bool hasCramping;
  final bool isAlertTriggered;
  final String? notes;

  const VaginalBleedingRecord({
    required this.id,
    required this.userId,
    required this.observationDate,
    required this.daysPriorAmenorrhea,
    this.flowIntensity = 'LIGHT',
    this.hasCramping = false,
    this.isAlertTriggered = false,
    this.notes,
  });
}
