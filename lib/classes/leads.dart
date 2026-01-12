class LeadMaster {
  final int leadID;
  final String customerName;
  final String customerCode;
  final String customerAddress;
  final String leadStageLevel;
  final int leadStage;
  final String leadStartDate;
  final String leadAging;
  final String leadAssigneeName;
  final String leadHospitalCode;
  final String leadDistributorCode;
  final int leadAssigneeId;
  final String leadDealValue;
  final String leadHospitalName;
  final String leadDistributorName;
  final int customerPaymentTerms;
  final double customerCreditLimit;
  final double customerMOV;
  final String leadProductName;

  final String leadType;
  final String leadCategory;
  final String leadBusinessType;
  final String leadPromotionType;
  final String leadSummary;
  final String leadStages;
  final String leadExpectedWithin;
  final String leadNextAction;
  final String leadNextActionDate;
  final String leadHelpRequired;
  final String leadInputMaterials;

  LeadMaster({
    required this.leadID,
    required this.customerName,
    required this.customerCode,
    required this.customerAddress,
    required this.leadStageLevel,
    required this.leadStage,
    required this.leadStartDate,
    required this.leadAging,
    required this.leadAssigneeName,
    required this.leadHospitalCode,
    required this.leadDistributorCode,
    required this.leadAssigneeId,
    required this.leadDealValue,
    required this.leadHospitalName,
    required this.leadDistributorName,
    required this.customerPaymentTerms,
    required this.customerCreditLimit,
    required this.customerMOV,
    required this.leadProductName,
    required this.leadType,
    this.leadCategory = "",
    this.leadBusinessType = "",
    this.leadPromotionType = "",
    this.leadSummary = "",
    this.leadStages = "",
    this.leadExpectedWithin = "",
    this.leadNextAction = "",
    this.leadNextActionDate = "",
    this.leadHelpRequired = "",
    this.leadInputMaterials = "",
  });

  factory LeadMaster.fromJson(Map<String, dynamic> json) {
    return LeadMaster(
      leadID: json['LeadID'] is int
          ? json['LeadID']
          : int.tryParse(json['LeadID'] ?? '') ?? 0,
      customerPaymentTerms: json['CustomerPaymentTerms'] is int
          ? json['CustomerPaymentTerms']
          : int.tryParse(json['CustomerPaymentTerms'] ?? '') ?? 0,
      customerCreditLimit: (json['CustomerCreditLimit'] ?? 0).toDouble(),
      customerMOV: (json['CustomerMOV'] ?? 0).toDouble(),
      customerName: json['CustomerName'],
      customerCode: json['CustomerCode'],
      customerAddress: json['AddressDetails'],
      leadStage: json['LeadStage'] is int
          ? json['LeadStage']
          : int.tryParse(json['LeadStage'] ?? '') ?? 0,
      leadStageLevel: json['LeadStageLevel'],
      leadStartDate: json['LeadStartDate'],
      leadAging: json['LeadAging'],
      leadAssigneeName: json['UserName'],
      leadHospitalCode: json['LeadHospitalCode'],
      leadDistributorCode: json['LeadDistributorCode'],
      leadAssigneeId: json['LeadAssigneeId'] is int
          ? json['LeadAssigneeId']
          : int.tryParse(json['LeadAssigneeId'] ?? '') ?? 0,
      leadDealValue: json['LeadDealValue'],
      leadHospitalName: json['CustomerName'],
      leadDistributorName: json['DistributorName'],
      leadProductName: json['LeadProductName'],
      leadType: json['LeadType'],
      leadCategory: json['LeadCategory'],
      leadBusinessType: json['LeadBusinessType'],
      leadPromotionType: json['LeadPromotionType'],
      leadSummary: json['LeadSummary'],
      leadStages: json['LeadStages'],
      leadExpectedWithin: json['LeadExpectedWithin'],
      leadNextAction: json['LeadNextAction'],
      leadNextActionDate: json['LeadNextActionDate'],
      leadHelpRequired: json['LeadHelpRequired'],
      leadInputMaterials: json['LeadInputMaterials'],
    );
  }
}

class LeadContact {
  final int leadContactId;
  final int leadContactParentId;
  final int leadContactMasterId;
  final String leadContactName;
  final String leadContactDesignation;
  final String leadContactDepartment;
  final String leadContactContactNo;
  final String leadContactEmailId;
  final String leadContactDecisionMaker;

  LeadContact({
    required this.leadContactId,
    required this.leadContactName,
    required this.leadContactDesignation,
    required this.leadContactDepartment,
    required this.leadContactContactNo,
    required this.leadContactEmailId,
    required this.leadContactDecisionMaker,
    required this.leadContactParentId,
    required this.leadContactMasterId,
  });

  // Add a factory method to create an instance from a map
  factory LeadContact.fromJson(Map<String, dynamic> json) {
    return LeadContact(
      leadContactId: json['LeadContactId'] is int
          ? json['LeadContactId']
          : int.tryParse(json['LeadContactId'] ?? '') ?? 0,
      leadContactParentId: json['LeadContactParentId'] is int
          ? json['LeadContactParentId']
          : int.tryParse(json['LeadContactParentId'] ?? '') ?? 0,
      leadContactMasterId: json['LeadContactMasterId'] is int
          ? json['LeadContactMasterId']
          : int.tryParse(json['LeadContactMasterId'] ?? '') ?? 0,
      leadContactName: json['LeadContactName'],
      leadContactDesignation: json['LeadContactDesignation'],
      leadContactDepartment: json['LeadContactDepartment'],
      leadContactContactNo: json['LeadContactContactNo'],
      leadContactEmailId: json['LeadContactEmailId'],
      leadContactDecisionMaker: json['LeadContactDecisionMaker'],
    );
  }
}

class LeadList {
  final int leadID;
  final String leadCustomerName;
  final String leadStageLevel;
  final String leadStartDate;
  final String leadAging;
  final String leadActivityType;
  final String leadFollowupDate;
  final String leadFollowupTime;

  LeadList({
    required this.leadID,
    required this.leadCustomerName,
    required this.leadStageLevel,
    required this.leadStartDate,
    required this.leadAging,
    required this.leadActivityType,
    required this.leadFollowupDate,
    required this.leadFollowupTime,
  });
  factory LeadList.fromJson(Map<String, dynamic> json) {
    String leadFollowupTime = json['LeadFollowupTime'] ?? '';
    String substringTime = leadFollowupTime.length >= 12
        ? leadFollowupTime.substring(12, leadFollowupTime.length)
        : leadFollowupTime;
    return LeadList(
      leadID: json['LeadID'] is int
          ? json['LeadID']
          : int.tryParse(json['LeadID'] ?? '') ?? 0,
      leadCustomerName: json['LeadCustomerName'],
      leadStageLevel: json['LeadStageLevel'],
      leadStartDate: json['LeadStartDate'],
      leadAging: json['LeadAging'],
      leadActivityType: json['LeadActivityType'],
      leadFollowupDate: json['LeadFollowupDate'],
      leadFollowupTime: substringTime,
    );
  }
}

class LeadProducts {
  final String leadProductName;
  final int leadProductId;
  final String leadCompetitorName;
  final double leadHospitalPrice;
  final double leadDistributorPrice;
  final String leadDateofPurchase;
  final double leadPurchasePrice;
  final String leadDateofSubmission;
  final String leadDclrNumber;
  final double leadTargetedPrice;
  final String leadRemark;
  final String leadTargetRemark;
  final String leadSamplePurchased;
  final String leadSampleSubmitted;
  final String leadAgingDays;
  final String leadHospitalCode;
  final String leadDistributorCode;
  final String leadDistributorName;
  final String leadStage3Id;
  final String leadStage3RecievedDate;
  final String leadStage3SubmittedDate;
  final String leadStage3ContactName;
  final String leadStage3ContactCode;
  final int leadStage3EntryId;
  final String leadStage4Id;
  final String leadStage4FeedbackDate;
  final String leadStage4Status;
  final String leadStage4SubmittedToHo;
  final String leadStage4Remarks;
  final int leadStage4EntryId;
  final String leadStage5Id;
  final String leadStage5DistributorCode;
  final String leadStage5QuotationDate;
  final String leadStage5QuotationRefNo;
  final String leadStage5QuotationStatus;
  final String leadStage5Remarks;
  final int leadStage5EntryId;
  final int leadStage6EntryId;
  final double leadTargetHP;
  final double leadTargetDP;

  LeadProducts(
      {required this.leadProductId,
      required this.leadProductName,
      required this.leadCompetitorName,
      required this.leadHospitalPrice,
      required this.leadDistributorPrice,
      required this.leadDateofPurchase,
      required this.leadPurchasePrice,
      required this.leadDateofSubmission,
      required this.leadDclrNumber,
      required this.leadTargetedPrice,
      required this.leadRemark,
      required this.leadTargetRemark,
      required this.leadSamplePurchased,
      required this.leadSampleSubmitted,
      required this.leadAgingDays,
      required this.leadHospitalCode,
      required this.leadDistributorCode,
      required this.leadDistributorName,
      required this.leadStage3Id,
      required this.leadStage3RecievedDate,
      required this.leadStage3SubmittedDate,
      required this.leadStage3ContactName,
      required this.leadStage3ContactCode,
      required this.leadStage3EntryId,
      required this.leadStage4Id,
      required this.leadStage4FeedbackDate,
      required this.leadStage4Status,
      required this.leadStage4SubmittedToHo,
      required this.leadStage4Remarks,
      required this.leadStage4EntryId,
      required this.leadStage5Id,
      required this.leadStage5DistributorCode,
      required this.leadStage5QuotationDate,
      required this.leadStage5QuotationRefNo,
      required this.leadStage5QuotationStatus,
      required this.leadStage5Remarks,
      required this.leadStage5EntryId,
      required this.leadStage6EntryId,
      required this.leadTargetHP,
      required this.leadTargetDP});

  factory LeadProducts.fromJson(Map<String, dynamic> json) {
    return LeadProducts(
      leadProductId: json['LeadProductId'],
      leadProductName: json['LeadProductName'],
      leadCompetitorName: json['LeadCompetitorName'],
      leadHospitalPrice: (json['LeadHospitalPrice'] ?? 0).toDouble(),
      leadDistributorPrice: (json['LeadDistributorPrice'] ?? 0).toDouble(),
      leadDateofPurchase: json['LeadDateofPurchase'],
      leadPurchasePrice: (json['LeadPurchasePrice'] ?? 0).toDouble(),
      leadTargetHP: (json['LeadTargetHP'] ?? 0).toDouble(),
      leadTargetDP: (json['LeadTargetDP'] ?? 0).toDouble(),
      leadDateofSubmission: json['LeadDateofSubmission'] ?? "00/00/2023",
      leadDclrNumber: json['LeadDclrNumber'],
      leadTargetedPrice: (json['LeadTargetedPrice'] ?? 0).toDouble(),
      leadRemark: json['LeadRemark'],
      leadTargetRemark: json['LeadTargetRemark'],
      leadSamplePurchased: json['LeadSamplePurchased'],
      leadSampleSubmitted: json['LeadSampleSubmitted'],
      leadAgingDays: json['LeadAgingDays'],
      leadHospitalCode: json['LeadHospitalCode'],
      leadDistributorCode: json['LeadDistributorCode'],
      leadDistributorName: json['LeadDistributorName'],
      leadStage3Id: json['LeadStage3Id'],
      leadStage3RecievedDate: json['LeadStage3RecievedDate'],
      leadStage3SubmittedDate: json['LeadStage3SubmittedDate'],
      leadStage3ContactName: json['LeadStage3ContactName'],
      leadStage3ContactCode: json['LeadStage3ContactCode'],
      leadStage3EntryId: json['LeadStage3EntryId'],
      leadStage4Id: json['LeadStage4Id'],
      leadStage4FeedbackDate: json['LeadStage4FeedbackDate'],
      leadStage4Status: json['LeadStage4Status'],
      leadStage4SubmittedToHo: json['LeadStage4SubmittedToHo'],
      leadStage4Remarks: json['LeadStage4Remarks'],
      leadStage4EntryId: json['LeadStage4EntryId'],
      leadStage5Id: json['LeadStage5Id'],
      leadStage5QuotationDate: json['LeadStage5QuotationDate'],
      leadStage5DistributorCode: json['LeadStage5DistributorCode'],
      leadStage5QuotationRefNo: json['LeadStage5QuotationRefNo'],
      leadStage5QuotationStatus: json['LeadStage5QuotationStatus'],
      leadStage5Remarks: json['LeadStage5Remarks'],
      leadStage5EntryId: json['LeadStage5EntryId'],
      leadStage6EntryId: json['LeadStage6EntryId'],
    );
  }
}

class LeadQuotation {
  final int leadStage5Id;
  final int leadStage5ProductId;
  final String leadStage5ProductName;
  final String leadStage5QuotationRefNo;
  final String leadStage5QuotationDate;
  final String leadStage5QuotationStatus;
  final String leadStage5Remarks;
  final int leadStage6EntryId;
  final int leadStage6Id;
  final String leadStage6PoNumber;
  final String leadStage6RefNo;
  final String leadStage6PoDate;
  final int leadStage7Id;
  final int leadStage7EntryId;
  final String leadStage7Status;
  final String leadStage7Remarks;
  final String leadCustomerName;

  LeadQuotation({
    required this.leadStage5Id,
    required this.leadStage5ProductId,
    required this.leadStage5ProductName,
    required this.leadStage5QuotationRefNo,
    required this.leadStage5QuotationDate,
    required this.leadStage5QuotationStatus,
    required this.leadStage5Remarks,
    required this.leadStage6EntryId,
    required this.leadStage6Id,
    required this.leadStage6PoNumber,
    required this.leadStage6RefNo,
    required this.leadStage6PoDate,
    required this.leadStage7Id,
    required this.leadStage7EntryId,
    required this.leadStage7Status,
    required this.leadStage7Remarks,
    required this.leadCustomerName,
  });

  factory LeadQuotation.fromJson(Map<String, dynamic> json) {
    return LeadQuotation(
      leadStage5Id: json['LeadStage5Id'] is int
          ? json['LeadStage5Id']
          : int.tryParse(json['LeadStage5Id'] ?? '') ?? 0,
      leadStage5ProductId: json['LeadStage5ProductId'] is int
          ? json['LeadStage5ProductId']
          : int.tryParse(json['LeadStage5ProductId'] ?? '') ?? 0,
      leadStage5ProductName: json['LeadStage5ProductName'],
      leadStage5QuotationRefNo: json['LeadStage5QuotationRefNo'],
      leadStage5QuotationDate: json['LeadStage5QuotationDate'],
      leadStage5QuotationStatus: json['LeadStage5QuotationStatus'],
      leadStage5Remarks: json['LeadStage5Remarks'],
      leadStage6EntryId: json['LeadStage6EntryId'],
      leadStage6Id: json['LeadStage6Id'] is int
          ? json['LeadStage6Id']
          : int.tryParse(json['LeadStage6Id'] ?? '') ?? 0,
      leadStage6PoNumber: json['LeadStage6PoNumber'],
      leadStage6RefNo: json['LeadStage6RefNo'],
      leadStage6PoDate: json['LeadStage6PoDate'],
      leadStage7Id: json['LeadStage7Id'] is int
          ? json['LeadStage7Id']
          : int.tryParse(json['LeadStage7Id'] ?? '') ?? 0,
      leadStage7EntryId: json['LeadStage7EntryId'],
      leadStage7Status: json['LeadStage7Status'],
      leadStage7Remarks: json['LeadStage7Remarks'],
      leadCustomerName: json['LeadCustomerName'],
    );
  }
}

class LeadActivity {
  final String leadType;
  final int leadActivityId;
  final int leadActivityMasterId;
  final int leadActivityStageLevel;
  final String leadActivitySummary;
  final String leadActivityFollowupDate;
  final String leadActivityLatitude;
  final String leadActivityLongitude;
  final String leadActivityLocation;
  final String leadActivityStatus;
  final String leadActivityStartDate;
  final String leadParticipantUserName;
  final String leadProductName;
  final String leadActivityDepartment;
  final String leadPriority;
  final String leadCustomerCode;
  final String leadCustomerName;
  final String leadActivityType;
  final String leadActivityTime;
  final String leadCategory;

  LeadActivity(
      {required this.leadType,
      required this.leadActivityId,
      required this.leadActivityMasterId,
      required this.leadActivityStageLevel,
      required this.leadActivitySummary,
      required this.leadActivityFollowupDate,
      required this.leadActivityLatitude,
      required this.leadActivityLongitude,
      required this.leadActivityLocation,
      required this.leadActivityStatus,
      required this.leadActivityStartDate,
      required this.leadParticipantUserName,
      required this.leadProductName,
      required this.leadActivityDepartment,
      required this.leadCustomerName,
      required this.leadCustomerCode,
      required this.leadPriority,
      required this.leadActivityType,
      required this.leadActivityTime,
      required this.leadCategory});

  factory LeadActivity.fromJson(Map<String, dynamic> json) {
    return LeadActivity(
      leadType: json['LeadType'],
      leadActivityId: json['LeadActivityId'] is int
          ? json['LeadActivityId']
          : int.tryParse(json['LeadActivityId'] ?? '') ?? 0,
      leadActivityMasterId: json['LeadActivityMasterId'] is int
          ? json['LeadActivityMasterId']
          : int.tryParse(json['LeadActivityMasterId'] ?? '') ?? 0,
      leadActivityStageLevel: json['LeadActivityStageLevel'] is int
          ? json['LeadActivityStageLevel']
          : int.tryParse(json['LeadActivityStageLevel'] ?? '') ?? 0,
      leadActivitySummary: json['LeadActivitySummary'],
      leadActivityFollowupDate: json['LeadActivityFollowupDate'],
      leadActivityLatitude: json['LeadActivityLatitude'],
      leadActivityLongitude: json['LeadActivityLongitude'],
      leadActivityLocation: json['LeadActivityLocation'],
      leadActivityStatus: json['LeadActivityStatus'],
      leadActivityStartDate: json['LeadActivityStartDate'],
      leadParticipantUserName: json['LeadParticipantUserName'],
      leadProductName: json['LeadProductName'],
      leadActivityDepartment: json['LeadActivityDepartment'],
      leadCustomerCode: json['LeadCustomerCode'],
      leadCustomerName: json['LeadCustomerName'],
      leadPriority: json['LeadPriority'],
      leadActivityType: json['LeadActivityType'],
      leadActivityTime: json['LeadActivityTime'],
      leadCategory: json['LeadCategory'],
    );
  }
}

class ScheduledLeadActivity {
  final String leadType;
  final int leadActivityId;
  final int leadActivityMasterId;
  final int leadActivityStageLevel;
  final String leadActivitySummary;
  final String leadActivityFollowupDate;
  final String leadActivityLatitude;
  final String leadActivityLongitude;
  final String leadActivityLocation;
  final String leadActivityStatus;
  final String leadActivityStartDate;
  final String leadParticipantUserName;
  final String leadProductName;
  final String leadActivityDepartment;
  final String leadPriority;
  final String leadCustomerCode;
  final String leadCustomerName;
  final String leadActivityType;
  final String leadActivityTime;
  final String leadCategory;

  ScheduledLeadActivity(
      {required this.leadType,
      required this.leadActivityId,
      required this.leadActivityMasterId,
      required this.leadActivityStageLevel,
      required this.leadActivitySummary,
      required this.leadActivityFollowupDate,
      required this.leadActivityLatitude,
      required this.leadActivityLongitude,
      required this.leadActivityLocation,
      required this.leadActivityStatus,
      required this.leadActivityStartDate,
      required this.leadParticipantUserName,
      required this.leadProductName,
      required this.leadActivityDepartment,
      required this.leadCustomerCode,
      required this.leadCustomerName,
      required this.leadPriority,
      required this.leadActivityType,
      required this.leadActivityTime,
      required this.leadCategory});

  factory ScheduledLeadActivity.fromJson(Map<String, dynamic> json) {
    return ScheduledLeadActivity(
      leadType: json['LeadType'],
      leadActivityId: json['LeadActivityId'] is int
          ? json['LeadActivityId']
          : int.tryParse(json['LeadActivityId'] ?? '') ?? 0,
      leadActivityMasterId: json['LeadActivityMasterId'] is int
          ? json['LeadActivityMasterId']
          : int.tryParse(json['LeadActivityMasterId'] ?? '') ?? 0,
      leadActivityStageLevel: json['LeadActivityStageLevel'] is int
          ? json['LeadActivityStageLevel']
          : int.tryParse(json['LeadActivityStageLevel'] ?? '') ?? 0,
      leadActivitySummary: json['LeadActivitySummary'],
      leadActivityFollowupDate: json['LeadActivityFollowupDate'],
      leadActivityLatitude: json['LeadActivityLatitude'],
      leadActivityLongitude: json['LeadActivityLongitude'],
      leadActivityLocation: json['LeadActivityLocation'],
      leadActivityStatus: json['LeadActivityStatus'],
      leadActivityStartDate: json['LeadActivityStartDate'],
      leadParticipantUserName: json['LeadParticipantUserName'],
      leadProductName: json['LeadProductName'],
      leadActivityDepartment: json['LeadActivityDepartment'],
      leadCustomerCode: json['LeadCustomerCode'],
      leadCustomerName: json['LeadCustomerName'],
      leadPriority: json['LeadPriority'],
      leadActivityType: json['LeadActivityType'],
      leadActivityTime: json['LeadActivityTime'],
      leadCategory: json['LeadCategory'],
    );
  }
}

class LeadParticipant {
  final int leadParticipantId;
  final int leadParticipantMasterId;
  final int leadParticipantUserId;
  final String leadParticipantUserName;

  LeadParticipant({
    required this.leadParticipantId,
    required this.leadParticipantMasterId,
    required this.leadParticipantUserId,
    required this.leadParticipantUserName,
  });

  factory LeadParticipant.fromJson(Map<String, dynamic> json) {
    return LeadParticipant(
      leadParticipantId: json['LeadParticipantId'] is int
          ? json['LeadParticipantId']
          : int.tryParse(json['LeadParticipantId']?.toString() ?? '') ?? 0,
      leadParticipantMasterId: json['LeadParticipantMasterId'] is int
          ? json['LeadParticipantMasterId']
          : int.tryParse(json['LeadParticipantMasterId']?.toString() ?? '') ?? 0,
      leadParticipantUserId: json['LeadParticipantUserId'] is int
          ? json['LeadParticipantUserId']
          : int.tryParse(json['LeadParticipantUserId']?.toString() ?? '') ?? 0,
      leadParticipantUserName: json['LeadParticipantUserName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'LeadParticipantId': leadParticipantId,
      'LeadParticipantMasterId': leadParticipantMasterId,
      'LeadParticipantUserId': leadParticipantUserId,
      'LeadParticipantUserName': leadParticipantUserName,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is LeadParticipant &&
              runtimeType == other.runtimeType &&
              leadParticipantUserId == other.leadParticipantUserId;

  @override
  int get hashCode => leadParticipantUserId.hashCode;

  @override
  String toString() => leadParticipantUserName;
}

class Users {
  final int menuId;
  final String menuName;
  final int subMenuId;
  final int parentMenuId;
  final int userLevel;

  Users({
    required this.menuId,
    required this.menuName,
    required this.subMenuId,
    required this.parentMenuId,
    required this.userLevel,
  });

  // Add a factory method to create an instance from a map
  factory Users.fromJson(Map<String, dynamic> json) {
    return Users(
      menuId: json['MenuId'] is int
          ? json['MenuId']
          : int.tryParse(json['MenuId'] ?? '') ?? 0,
      menuName: json['MenuName'],
      subMenuId: json['SubMenuId'] is int
          ? json['SubMenuId']
          : int.tryParse(json['SubMenuId'] ?? '') ?? 0,
      parentMenuId: json['ParentMenuId'] is int
          ? json['ParentMenuId']
          : int.tryParse(json['ParentMenuId'] ?? '') ?? 0,
      userLevel: json['UserLevel'] is int
          ? json['UserLevel']
          : int.tryParse(json['UserLevel'] ?? '') ?? 0,
    );
  }
}

class ProductCategoryList {
  final int prodCatgId;
  String prodCatgName;
  ProductCategoryList({
    required this.prodCatgId,
    required this.prodCatgName,
  });
}

class CheckinDetails {
  final int checkinId;
  final int checkinUserId;
  final String checkinCustomerType;
  final String checkinCustomerCode;
  final String checkinTime;
  final String checkinLatitude;
  final String checkinLongitude;
  final String checkinLocation;
  final String checkoutTime;
  final String checkoutLatitude;
  final String checkoutLongitude;
  final String checkoutLocation;
  final String checkinCustomerName;
  final String checkinDisplayTime;
  final String checkinPlaceOfVisit;

  CheckinDetails(
      {required this.checkinId,
      required this.checkinUserId,
      required this.checkinCustomerType,
      required this.checkinCustomerCode,
      required this.checkinTime,
      required this.checkinLatitude,
      required this.checkinLongitude,
      required this.checkinLocation,
      required this.checkoutTime,
      required this.checkoutLatitude,
      required this.checkoutLongitude,
      required this.checkoutLocation,
      required this.checkinCustomerName,
      required this.checkinDisplayTime,
      required this.checkinPlaceOfVisit});

  factory CheckinDetails.fromJson(Map<String, dynamic> json) {
    return CheckinDetails(
      checkinId: json['CheckinId'] is int
          ? json['CheckinId']
          : int.tryParse(json['CheckinId'] ?? '') ?? 0,
      checkinUserId: json['CheckinUserId'] is int
          ? json['CheckinUserId']
          : int.tryParse(json['CheckinUserId'] ?? '') ?? 0,
      checkinCustomerType: json['CheckinCustomerType'],
      checkinCustomerCode: json['CheckinCustomerCode'],
      checkinTime: json['CheckinTime'],
      checkinLatitude: json['CheckinLatitude'],
      checkinLongitude: json['CheckinLongitude'],
      checkinLocation: json['CheckinLocation'],
      checkoutTime: json['CheckoutTime'],
      checkoutLatitude: json['CheckoutLatitude'],
      checkoutLongitude: json['CheckoutLongitude'],
      checkoutLocation: json['CheckoutLocation'],
      checkinCustomerName: json['CheckinCustomerName'],
      checkinDisplayTime: json['CheckinDisplayTime'],
      checkinPlaceOfVisit: json['CheckinPlaceOfVisit'],
    );
  }
}
