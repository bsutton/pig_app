class LightingInfo {
  final int id;

  final String name;

  final bool isOn;

  final int lightSwitchId;

  final String? lastOnDate;

  final bool timerRunning;

  final int timerRemainingSeconds;

  LightingInfo({
    required this.id,
    required this.name,
    required this.isOn,
    required this.lightSwitchId,
    required this.timerRunning,
    required this.timerRemainingSeconds,
    this.lastOnDate,
  });

  factory LightingInfo.fromJson(Map<String, dynamic> json) => LightingInfo(
    id: json['id'] as int,
    name: json['name'] as String,
    isOn: json['isOn'] as bool,
    lightSwitchId: json['lightSwitchId'] as int,
    lastOnDate: json['lastOnDate'] as String?,
    timerRunning: json['timerRunning'] as bool,
    timerRemainingSeconds: json['timerRemainingSeconds'] as int,
  );
}
