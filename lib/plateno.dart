class PlateNo {
  final String plate_no;
  final dynamic type;
  // final String vehiclename;
  final String trucker;

  PlateNo(
      {required this.plate_no,
      required this.type,
      //required this.vehiclename,
      required this.trucker});

  factory PlateNo.fromJson(Map<String, dynamic> json) {
    return PlateNo(
        plate_no: json['plate_no'],
        type: json['type'],
        //  vehiclename: json['vehiclename'],
        trucker: json['trucker']);
  }
}
