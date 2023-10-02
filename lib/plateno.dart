class PlateNo {
  final dynamic plate_no;
  final dynamic type;
  final dynamic trucker;

  PlateNo({required this.plate_no, this.type, this.trucker});

  factory PlateNo.fromJson(Map<String, dynamic> json) {
    return PlateNo(plate_no: json['plate_no'] ?? '', type: json['type'] ?? '', trucker: json['trucker'] ?? '');
  }
  Map<String, dynamic> toJson() => {
        "type": type,
        "plate_no": plate_no,
        "trucker": trucker,
      };
}
