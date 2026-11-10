enum Straw10Stage {
  lateReproductive('LATE_REPRODUCTIVE'),
  earlyTransition('EARLY_TRANSITION'),
  lateTransition('LATE_TRANSITION'),
  postmenopause('POSTMENOPAUSE');

  final String value;
  const Straw10Stage(this.value);
}

class MenopauseClinicalAlert {
  final String code;
  final String severity; // URGENT_EMERGENCY, WARNING, INFO
  final String title;
  final String clinicalGuidance;
  final bool requiresImmediateEvaluation;

  const MenopauseClinicalAlert({
    required this.code,
    required this.severity,
    required this.title,
    required this.clinicalGuidance,
    required this.requiresImmediateEvaluation,
  });
}

class MenopauseOfflineEvaluator {
  const MenopauseOfflineEvaluator();

  Straw10Stage classifyStraw10({
    required int age,
    required List<int> consecutiveCycleLengths,
    required int daysSinceLastMenstruation,
  }) {
    // 1. Postmenopause: >= 365 days of amenorrhea
    if (daysSinceLastMenstruation >= 365) {
      return Straw10Stage.postmenopause;
    }

    // 2. Late transition: >= 60 days amenorrhea
    if (daysSinceLastMenstruation >= 60) {
      return Straw10Stage.lateTransition;
    }

    // 3. Early transition: difference >= 7 days in consecutive cycles
    if (consecutiveCycleLengths.length >= 2) {
      for (int i = 0; i < consecutiveCycleLengths.length - 1; i++) {
        final diff =
            (consecutiveCycleLengths[i + 1] - consecutiveCycleLengths[i]).abs();
        if (diff >= 7) {
          return Straw10Stage.earlyTransition;
        }
      }
    }

    return Straw10Stage.lateReproductive;
  }

  MenopauseClinicalAlert? evaluateBleedingSafety({
    required int daysPriorAmenorrhea,
  }) {
    if (daysPriorAmenorrhea >= 365) {
      return const MenopauseClinicalAlert(
        code: 'POSTMENOPAUSAL_BLEEDING_ALERT',
        severity: 'URGENT_EMERGENCY',
        title: 'Alerta de Sangrado Posmenopáusico',
        clinicalGuidance:
            'Se registró sangrado vaginal tras 12 o más meses de amenorrea. '
            'Requiere valoración ginecológica prioritaria con ecografía '
            'transvaginal para evaluar el grosor endometrial.',
        requiresImmediateEvaluation: true,
      );
    }
    return null;
  }
}
