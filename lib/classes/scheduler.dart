class MonthlySchedule {
  final int scheduleID;
  final String scheduledUser;
  final int scheduleUserId;
  final String scheduleDate;
  final String scheduleCustomerCode;
  final String scheduleCustomerName;
  final String scheduleCustomerType;
  final String scheduleRemarks;
  final String schedulePriority;
  String scheduleStatus;
  final List<ScheduleParticipant> participantList;

  static String formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return "${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateString;
    }
  }

  MonthlySchedule(
      {required this.scheduleID,
      required this.scheduleUserId,
      required this.scheduleDate,
      required this.scheduledUser,
      required this.scheduleCustomerCode,
      required this.scheduleCustomerName,
      required this.scheduleCustomerType,
      required this.scheduleRemarks,
      required this.schedulePriority,
      required this.scheduleStatus,
      required this.participantList});

  factory MonthlySchedule.fromJson(Map<String, dynamic> json) {
    return MonthlySchedule(
      scheduleID: json['ScheduleID'] is int
          ? json['ScheduleID']
          : int.tryParse(json['ScheduleID']?.toString() ?? '') ?? 0,
      scheduleUserId: json['ScheduleUserId'] is int
          ? json['ScheduleUserId']
          : int.tryParse(json['ScheduleUserId']?.toString() ?? '') ?? 0,
      scheduleDate: formatDate(json['ScheduleDate']?.toString() ?? ''),
      scheduleCustomerCode: json['ScheduleCustomerCode'] ?? '',
      scheduledUser: json['ScheduledUser'] ?? '',
      scheduleCustomerName: json['ScheduleCustomerName'] ?? '',
      scheduleCustomerType: json['ScheduleCustomerType'] ?? '',
      scheduleRemarks: json['ScheduleRemarks'] ?? '',
      schedulePriority: json['SchedulePriority'] ?? '',
      scheduleStatus: json['ScheduleStatus'] ?? '',
      participantList: (json['participantList'] as List<dynamic>?)
              ?.map((e) => ScheduleParticipant.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ScheduleID': scheduleID,
      'ScheduleUserId': scheduleUserId,
      'ScheduleDate': scheduleDate,
      'ScheduledUser': scheduledUser,
      'ScheduleCustomerCode': scheduleCustomerCode,
      'ScheduleCustomerName': scheduleCustomerName,
      'ScheduleCustomerType': scheduleCustomerType,
      'ScheduleRemarks': scheduleRemarks,
      'SchedulePriority': schedulePriority,
      'ScheduleStatus': scheduleStatus,
      'participantList': participantList.map((e) => e.toJson()).toList(),
    };
  }
}

class ScheduleParticipant {
  final int scheduleParticipantId;
  final int scheduleParticipantMasterId;
  final int scheduleParticipantUserId;
  final String scheduleParticipantUserName;

  ScheduleParticipant(
      {required this.scheduleParticipantId,
      required this.scheduleParticipantMasterId,
      required this.scheduleParticipantUserId,
      required this.scheduleParticipantUserName});

  factory ScheduleParticipant.fromJson(Map<String, dynamic> json) {
    return ScheduleParticipant(
      scheduleParticipantId: json['ScheduleParticipantId'] is int
          ? json['ScheduleParticipantId']
          : int.tryParse(json['ScheduleParticipantId']?.toString() ?? '') ?? 0,
      scheduleParticipantMasterId: json['ScheduleParticipantMasterId'] is int
          ? json['ScheduleParticipantMasterId']
          : int.tryParse(
                  json['ScheduleParticipantMasterId']?.toString() ?? '') ??
              0,
      scheduleParticipantUserId: json['ScheduleParticipantUserId'] is int
          ? json['ScheduleParticipantUserId']
          : int.tryParse(json['ScheduleParticipantUserId']?.toString() ?? '') ??
              0,
      scheduleParticipantUserName: json['ScheduleParticipantUserName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ScheduleParticipantId': scheduleParticipantId,
      'ScheduleParticipantMasterId': scheduleParticipantMasterId,
      'ScheduleParticipantUserId': scheduleParticipantUserId,
      'ScheduleParticipantUserName': scheduleParticipantUserName,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleParticipant &&
          other.scheduleParticipantUserId == scheduleParticipantUserId;

  @override
  int get hashCode => scheduleParticipantUserId.hashCode;
}

class MonthlyScheduleHomePage {
  final String scheduleType;
  final String sheduledUser;
  final String participantName;
  final String scheduleCustomerName;
  final int scheduleID;
  final int scheduleUserId;
  final String scheduleDate;
  final String scheduleCustomerCode;
  final String scheduleCustomerType;
  final String scheduleRemarks;
  final String schedulePriority;
  String scheduleStatus;
  final String entryDate;

  static String formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return "${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateString;
    }
  }

  MonthlyScheduleHomePage({
    required this.scheduleID,
    required this.scheduleType,
    required this.sheduledUser,
    required this.participantName,
    required this.scheduleUserId,
    required this.scheduleDate,
    required this.scheduleCustomerCode,
    required this.scheduleCustomerName,
    required this.scheduleCustomerType,
    required this.scheduleRemarks,
    required this.schedulePriority,
    required this.scheduleStatus,
    required this.entryDate,
  });

  factory MonthlyScheduleHomePage.fromJson(Map<String, dynamic> json) {
    return MonthlyScheduleHomePage(
      scheduleID: json['ScheduleID'] is int
          ? json['ScheduleID']
          : int.tryParse(json['ScheduleID']?.toString() ?? '') ?? 0,
      scheduleUserId: json['ScheduleUserId'] is int
          ? json['ScheduleUserId']
          : int.tryParse(json['ScheduleUserId']?.toString() ?? '') ?? 0,
      scheduleDate: formatDate(json['ScheduleDate']?.toString() ?? ''),
      scheduleCustomerCode: json['ScheduleCustomerCode'] ?? '',
      scheduleType: json['ScheduleType'] ?? '',
      sheduledUser: json['ScheduledUser'] ?? '',
      participantName: json['ParticipantName'] ?? '',
      scheduleCustomerName: json['ScheduleCustomerName'] ?? '',
      scheduleCustomerType: json['ScheduleCustomerType'] ?? '',
      scheduleRemarks: json['ScheduleRemarks'] ?? '',
      schedulePriority: json['SchedulePriority'] ?? '',
      scheduleStatus: json['ScheduleStatus'] ?? '',
      entryDate: json['EntryDate'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ScheduleID': scheduleID,
      'ScheduleType': scheduleType,
      'ScheduledUser': sheduledUser,
      'ParticipantName': participantName,
      'ScheduleUserId': scheduleUserId,
      'ScheduleDate': scheduleDate,
      'ScheduleCustomerCode': scheduleCustomerCode,
      'ScheduleCustomerName': scheduleCustomerName,
      'ScheduleCustomerType': scheduleCustomerType,
      'ScheduleRemarks': scheduleRemarks,
      'SchedulePriority': schedulePriority,
      'ScheduleStatus': scheduleStatus,
      'EntryDate': entryDate,
    };
  }
}
