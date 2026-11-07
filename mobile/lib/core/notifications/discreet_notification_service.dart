enum NotificationType {
  wellnessCheckin,
  treatmentIntake,
  larcReplacement,
}

class NotificationContent {
  final String title;
  final String body;

  const NotificationContent({
    required this.title,
    required this.body,
  });
}

class DiscreetNotificationService {
  static const String defaultMaskedTitle = 'Cora';
  static const String defaultMaskedBody =
      'Tienes un recordatorio de bienestar en Cora';

  /// Returns notification copy respecting the user's discretion / privacy setting.
  NotificationContent formatReminder({
    required NotificationType type,
    required String detailedTitle,
    required String detailedBody,
    bool isDiscreet = true,
  }) {
    if (isDiscreet) {
      return const NotificationContent(
        title: defaultMaskedTitle,
        body: defaultMaskedBody,
      );
    }

    return NotificationContent(
      title: detailedTitle,
      body: detailedBody,
    );
  }
}
