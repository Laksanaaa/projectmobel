
import 'package:flutter/material.dart';

import '../models/employee.dart';
import '../services/employee_service.dart';
import 'add_employee_page.dart';

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({super.key});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  final EmployeeService _service = EmployeeService();

  late Future<List<Employee>> _employeesFuture;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  void _loadEmployees() {
    _employeesFuture = _service.getEmployees();
  }

  String _formatRupiah(double value) {
    final amount = value.toInt().toString();
    final formatted = amount.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return 'Rp $formatted';
  }

  Future<void> _refreshEmployees() async {
    setState(_loadEmployees);
    await _employeesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Karyawan'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(_loadEmployees);
            },
          ),
        ],
      ),
      
floatingActionButton: FloatingActionButton.extended(
  onPressed: () async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEmployeePage(),
      ),
    );

    if (result == true && mounted) {
      setState(_loadEmployees);
    }
  },
  icon: const Icon(Icons.person_add),
  label: const Text('Tambah Karyawan'),
),

      body: FutureBuilder<List<Employee>>(
        future: _employeesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Gagal memuat data karyawan.',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(_loadEmployees);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final employees = snapshot.data ?? [];

          if (employees.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshEmployees,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 160),
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text('Belum ada data karyawan.'),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Tarik layar ke bawah untuk memuat ulang.',
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshEmployees,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.groups),
                    ),
                    title: const Text('Total Karyawan'),
                    subtitle: const Text(
                      'Data dari database café',
                    ),
                    trailing: Text(
                      '${employees.length}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...employees.map(
                  (employee) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        child: Text(
                          employee.fullName.isNotEmpty
                              ? employee.fullName[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(
                        employee.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${employee.employeeCode} • '
                              '${employee.position}',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Telepon: ${employee.phone ?? '-'}',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tarif/shift: '
                              '${_formatRupiah(employee.shiftRate)}',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Mulai bekerja: ${employee.hireDate}',
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  employee.isActive
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  size: 16,
                                  color: employee.isActive
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  employee.isActive
                                      ? 'Aktif'
                                      : 'Tidak aktif',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}