enum BiometricLockTimeout {
  immediate,
  oneMinute,
  fiveMinutes,
}

class BiometricLockService {
  BiometricLockService({
    bool isBiometricEnabled = false,
    BiometricLockTimeout timeout = BiometricLockTimeout.immediate,
  })  : _isBiometricEnabled = isBiometricEnabled,
        _timeout = timeout;

  bool _isBiometricEnabled;
  BiometricLockTimeout _timeout;
  DateTime? _lastPausedAt;
  bool _isUnlocked = true;

  bool get isBiometricEnabled => _isBiometricEnabled;
  BiometricLockTimeout get timeout => _timeout;
  bool get isUnlocked => _isUnlocked;

  void setBiometricEnabled(bool enabled) {
    _isBiometricEnabled = enabled;
  }

  void setTimeout(BiometricLockTimeout timeout) {
    _timeout = timeout;
  }

  void recordAppPaused() {
    if (_isBiometricEnabled) {
      _lastPausedAt = DateTime.now();
    }
  }

  bool checkRequiresAuthenticationOnResume({DateTime? currentTime}) {
    if (!_isBiometricEnabled || _lastPausedAt == null) {
      return false;
    }
    final now = currentTime ?? DateTime.now();
    final elapsedSeconds = now.difference(_lastPausedAt!).inSeconds;

    bool shouldLock = false;
    switch (_timeout) {
      case BiometricLockTimeout.immediate:
        shouldLock = true;
        break;
      case BiometricLockTimeout.oneMinute:
        shouldLock = elapsedSeconds >= 60;
        break;
      case BiometricLockTimeout.fiveMinutes:
        shouldLock = elapsedSeconds >= 300;
        break;
    }

    if (shouldLock) {
      _isUnlocked = false;
    }
    return shouldLock;
  }

  Future<bool> authenticateMock({bool success = true}) async {
    if (success) {
      _isUnlocked = true;
      _lastPausedAt = null;
      return true;
    }
    return false;
  }
}
