import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum DiscreetAppIcon {
  coraDefault,
  neutralCalendar,
  neutralNotes,
  pocketCalculator,
}

class DiscreetAppIconService extends ChangeNotifier {
  static const MethodChannel _channel =
      MethodChannel('com.cora.health.mobile/discreet_icon');

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

  Future<void> syncFromNative() async {
    try {
      final aliasName = await _channel.invokeMethod<String>('getDiscreetIcon');
      if (aliasName != null) {
        final matched = DiscreetAppIcon.values
            .where((e) => e.name == aliasName)
            .firstOrNull;
        if (matched != null && matched != _currentIcon) {
          _currentIcon = matched;
          notifyListeners();
        }
      }
    } catch (_) {
      // Ignore on unsupported platforms or unit tests without MethodChannel
    }
  }

  void switchIcon(DiscreetAppIcon newIcon) {
    if (_currentIcon != newIcon) {
      _currentIcon = newIcon;
      notifyListeners();
      unawaited(_applyNativeIcon(newIcon));
    }
  }

  Future<void> _applyNativeIcon(DiscreetAppIcon icon) async {
    try {
      await _channel.invokeMethod<bool>(
        'setDiscreetIcon',
        {'alias': icon.name},
      );
    } catch (_) {
      // Safe no-op in tests or platforms without activity-alias support
    }
  }
}
