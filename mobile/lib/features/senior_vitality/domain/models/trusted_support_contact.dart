class TrustedSupportContact {
  final String id;
  final String userId;
  final String contactName;
  final String relationship;
  final String phoneNumber;
  final String? notes;
  final bool isPrimary;

  const TrustedSupportContact({
    required this.id,
    required this.userId,
    required this.contactName,
    required this.relationship,
    required this.phoneNumber,
    this.notes,
    this.isPrimary = true,
  });
}
