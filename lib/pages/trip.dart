class Trip {
  dynamic id;
  dynamic reference;
  dynamic status;
  dynamic plateNo;
  dynamic scheduleFrom;
  dynamic scheduleTo;
  List<Booking> booking;

  Trip({
    required this.id,
    required this.reference,
    required this.status,
    required this.plateNo,
    required this.scheduleFrom,
    required this.scheduleTo,
    required this.booking,
  });

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        id: json["id"],
        reference: json["reference"],
        status: json["status"],
        plateNo: json["plate_no"],
        scheduleFrom: json["schedule_from"],
        scheduleTo: json["schedule_to"],
        booking: List<Booking>.from(json["booking"].map((x) => Booking.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "reference": reference,
        "status": status,
        "plate_no": plateNo,
        "schedule_from": scheduleFrom,
        "schedule_to": scheduleTo,
        "booking": List<dynamic>.from(booking.map((x) => x.toJson())),
      };
}

class Booking {
  dynamic runsheetId;
  dynamic bookingId;
  dynamic reference;
  dynamic status;
  dynamic statusName;
  dynamic task;
  dynamic customer;
  dynamic deliveryContactNo;
  dynamic deliveryToCode;
  dynamic deliveryName;
  dynamic deliveryCity;
  dynamic deliveryContactPerson;
  dynamic deliveryExpectedDate;
  dynamic deliveryOtherAddress;
  dynamic pickupCity;
  dynamic pickupContactNo;
  dynamic pickupContactPerson;
  dynamic pickupExpectedDate;
  dynamic pickupFrCode;
  dynamic pickupName;
  dynamic pickupOtherAddress;
  dynamic remarks;
  dynamic totalCbm;
  dynamic totalQty;
  dynamic totalSqm;
  dynamic totalWt;

  Booking({
    this.runsheetId,
    this.bookingId,
    this.reference,
    this.status,
    this.statusName,
    this.task,
    this.customer,
    this.deliveryContactNo,
    this.deliveryToCode,
    this.deliveryName,
    this.deliveryCity,
    this.deliveryContactPerson,
    this.deliveryExpectedDate,
    this.deliveryOtherAddress,
    this.pickupCity,
    this.pickupContactNo,
    this.pickupContactPerson,
    this.pickupExpectedDate,
    this.pickupFrCode,
    this.pickupName,
    this.pickupOtherAddress,
    this.remarks,
    this.totalCbm,
    this.totalQty,
    this.totalSqm,
    this.totalWt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        runsheetId: json["runsheet_id"],
        bookingId: json["booking_id"],
        reference: json["reference"],
        status: json["status"],
        statusName: json["status_name"],
        task: json["task"],
        customer: json["customer"] ?? '',
        deliveryContactNo: json["delivery_contact_no"] ?? '',
        deliveryToCode: json["delivery_to_code"] ?? '',
        deliveryName: json["delivery_name"] ?? '',
        deliveryCity: json["delivery_city"] ?? '',
        deliveryContactPerson: json["delivery_contact_person"] ?? '',
        deliveryExpectedDate: json["delivery_expected_date"] ?? '',
        deliveryOtherAddress: json["delivery_other_address"] ?? '',
        pickupCity: json["pickup_city"] ?? '',
        pickupContactNo: json["pickup_contact_no"] ?? '',
        pickupContactPerson: json["pickup_contact_person"] ?? '',
        pickupExpectedDate: json["pickup_expected_date"] ?? '',
        pickupFrCode: json["pickup_fr_code"] ?? '',
        pickupName: json["pickup_name"] ?? '',
        pickupOtherAddress: json["pickup_other_address"] ?? '',
        remarks: json["remarks"] ?? '',
        totalCbm: json["total_cbm"] ?? '',
        totalQty: json["total_qty"] ?? '',
        totalSqm: json["total_sqm"] ?? '',
        totalWt: json["total_wt"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "runsheet_id": runsheetId,
        "booking_id": bookingId,
        "reference": reference,
        "status": status,
        "status_name": statusName,
        "task": task,
        "delivery_contact_no": deliveryContactNo,
        "delivery_to_code": deliveryToCode,
        "delivery_name": deliveryName,
        "delivery_city": deliveryCity,
        "delivery_contact_person": deliveryContactPerson,
        "delivery_expected_date": deliveryExpectedDate,
        "delivery_other_address": deliveryOtherAddress,
        "pickup_city": pickupCity,
        "pickup_contact_no": pickupContactNo,
        "pickup_contact_person": pickupContactPerson,
        "pickup_expected_date": pickupExpectedDate,
        "pickup_fr_code": pickupFrCode,
        "pickup_name": pickupName,
        "pickup_other_address": pickupOtherAddress,
        "remarks": remarks,
        "total_cbm": totalCbm,
        "total_qty": totalQty,
        "total_sqm": totalSqm,
        "total_wt": totalWt,
      };
}
