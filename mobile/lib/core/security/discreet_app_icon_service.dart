import 'package:flutter/foundation.dart';

enum DiscreetAppIcon {
  coraDefault,
  neutralCalendar,
  neutralNotes,
  pocketCalculator,
}

class DiscreetAppIconService extends ChangeNotifier {
  DiscreetAppIconService({
    DiscreetAppIcon currentIcon = DiscreetAppIcon.coraDefault,
  }) : _currentIcon = currentIcon;

  DiscreetAppIcon _currentIcon;

  DiscreetAppIcon get currentIcon => _currentIcon;

  String get currentDisplayName {
    switch (_currentIcon) {
      case DiscreetAppIcon.coraDefault:
        return 'Cora';
      case DiscreetAppIcon.neutralCalendar:
        return 'Mi Calendario';
      case DiscreetAppIcon.neutralNotes:
        return 'Mis Notas';
      case DiscreetAppIcon.pocketCalculator:
        return 'Calculadora';
    }
  }

  void switchIcon(DiscreetAppIcon newIcon) {
    if (_currentIcon != newIcon) {
      _currentIcon = newIcon;
      notifyListeners();
    }
  }
}
