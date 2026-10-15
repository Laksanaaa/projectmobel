
class Employee {
  final int id;
  final String employeeCode;
  final String fullName;
  final String? phone;
  final String position;
  final double shiftRate;
  final String hireDate;
  final bool isActive;

  const Employee({
    required this.id,
    required this.employeeCode,
    required this.fullName,
    this.phone,
    required this.position,
    required this.shiftRate,
    required this.hireDate,
    required this.isActive,
  });

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: int.parse(map['id'].toString()),
      employeeCode: map['employee_code'].toString(),
      fullName: map['full_name'].toString(),
      phone: map['phone']?.toString(),
      position: map['position'].toString(),
      shiftRate: double.parse(map['shift_rate'].toString()),
      hireDate: map['hire_date'].toString(),
      isActive: map['is_active'] == true ||
          map['is_active'] == 1 ||
          map['is_active'] == '1',
    );
  }
}
