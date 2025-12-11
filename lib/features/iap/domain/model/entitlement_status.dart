enum EntitlementStatus {
  entitled, // активна
  expired, // срок закончился
  inGrace, // льготный период (платёж не прошел, доступ еще есть)
  revoked, // отозвана (refund / revoke)
  none, // нет подписки
}

extension EntitlementX on EntitlementStatus {
  bool get isUnlocked =>
      this == EntitlementStatus.entitled || this == EntitlementStatus.inGrace;

  String get label => switch (this) {
        EntitlementStatus.entitled => 'ENTITLED',
        EntitlementStatus.expired => 'EXPIRED',
        EntitlementStatus.inGrace => 'IN_GRACE',
        EntitlementStatus.revoked => 'REVOKED',
        EntitlementStatus.none => 'NONE',
      };

  static EntitlementStatus fromServer(String? s) {
    final norm = (s ?? 'NONE').toUpperCase().replaceAll('-', '_');
    return EntitlementStatus.values.firstWhere(
      (e) => e.label == norm,
      orElse: () => EntitlementStatus.none,
    );
  }
}
