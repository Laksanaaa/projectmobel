
class Shift {
  final int id;
  final int employeeId;
  final String employeeCode;
  final String employeeName;
  final String position;
  final String branch;
  final String shiftDate;
  final String startTime;
  final String endTime;

  const Shift({
    required this.id,
    required this.employeeId,
    required this.employeeCode,
    required this.employeeName,
    required this.position,
    required this.branch,
    required this.shiftDate,
    required this.startTime,
    required this.endTime,
  });

  factory Shift.fromMap(Map<String, dynamic> map) {
    return Shift(
      id: int.parse(map['id'].toString()),
      employeeId: int.parse(map['employee_id'].toString()),
      employeeCode: map['employee_code']?.toString() ?? '',
      employeeName: (
        map['full_name'] ?? map['employee_name'] ?? ''
      ).toString(),
      position: map['position']?.toString() ?? '',
      branch: map['branch'].toString(),
      shiftDate: map['shift_date'].toString(),
      startTime: map['start_time'].toString(),
      endTime: map['end_time'].toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'employee_code': employeeCode,
      'full_name': employeeName,
      'position': position,
      'branch': branch,
      'shift_date': shiftDate,
      'start_time': startTime,
      'end_time': endTime,
    };
  }

  String get branchName => 'Cabang $branch';

  String get formattedTime {
    return '${startTime.substring(0, 5)} - '
        '${endTime.substring(0, 5)}';
  }
}
