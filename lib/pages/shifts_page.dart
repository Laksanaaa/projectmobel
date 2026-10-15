
import 'package:flutter/material.dart';

import '../models/employee.dart';
import '../models/shift.dart';
import '../services/employee_service.dart';
import '../services/shift_service.dart';

class ShiftsPage extends StatefulWidget {
  const ShiftsPage({super.key});

  @override
  State<ShiftsPage> createState() => _ShiftsPageState();
}

class _ShiftsPageState extends State<ShiftsPage> {
  final EmployeeService _employeeService = EmployeeService();
  final ShiftService _shiftService = ShiftService();

  late Future<List<Shift>> _shiftsFuture;

  String _selectedBranch = 'Semua';

  @override
  void initState() {
    super.initState();
    _loadShifts();
  }

  void _loadShifts() {
    _shiftsFuture = _shiftService.getShifts(
      branch: _selectedBranch == 'Semua'
          ? null
          : _selectedBranch,
    );
  }

  Future<void> _refreshShifts() async {
    setState(_loadShifts);
    await _shiftsFuture;
  }

  Future<void> _showAddShiftDialog() async {
    List<Employee> employees;

    try {
      employees = await _employeeService.getEmployees();
      employees = employees.where((e) => e.isActive).toList();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil karyawan: $e'),
        ),
      );
      return;
    }

    if (!mounted) return;

    if (employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Belum ada karyawan aktif. Tambahkan karyawan dahulu.',
          ),
        ),
      );
      return;
    }

    int? selectedEmployeeId;
    String selectedBranch = 'A';
    DateTime selectedDate = DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Jadwal Shift'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pilih Karyawan'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: selectedEmployeeId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Pilih karyawan'),
                      items: employees.map((employee) {
                        return DropdownMenuItem<int>(
                          value: employee.id,
                          child: Text(
                            '${employee.employeeCode} - '
                            '${employee.fullName}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: isSaving
                          ? null
                          : (value) {
                              setDialogState(() {
                                selectedEmployeeId = value;
                              });
                            },
                    ),
                    const SizedBox(height: 16),
                    const Text('Pilih Cabang'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedBranch,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'A',
                          child: Text('Cabang A (18.00–01.00)'),
                        ),
                        DropdownMenuItem(
                          value: 'B',
                          child: Text('Cabang B (19.30–03.30)'),
                        ),
                      ],
                      onChanged: isSaving
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() {
                                  selectedBranch = value;
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 16),
                    const Text('Tanggal Shift'),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        '${selectedDate.day.toString().padLeft(2, '0')}/'
                        '${selectedDate.month.toString().padLeft(2, '0')}/'
                        '${selectedDate.year}',
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2025),
                                lastDate: DateTime(2035),
                              );

                              if (picked != null) {
                                setDialogState(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Jam kerja ditentukan otomatis berdasarkan cabang.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (selectedEmployeeId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Pilih karyawan terlebih dahulu.',
                                ),
                              ),
                            );
                            return;
                          }

                          final date =
                              '${selectedDate.year}-'
                              '${selectedDate.month.toString().padLeft(2, '0')}-'
                              '${selectedDate.day.toString().padLeft(2, '0')}';

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            await _shiftService.addShift(
                              employeeId: selectedEmployeeId!,
                              branch: selectedBranch,
                              shiftDate: date,
                            );

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          } catch (e) {
                            if (!dialogContext.mounted) return;

                            setDialogState(() {
                              isSaving = false;
                            });

                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceFirst(
                                    'Exception: ',
                                    '',
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      setState(_loadShifts);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jadwal shift berhasil ditambahkan.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _shiftService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Shift'),
        actions: [
          IconButton(
            onPressed: _refreshShifts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddShiftDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Jadwal'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedBranch,
              decoration: const InputDecoration(
                labelText: 'Filter Cabang',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Semua',
                  child: Text('Semua Cabang'),
                ),
                DropdownMenuItem(
                  value: 'A',
                  child: Text('Cabang A'),
                ),
                DropdownMenuItem(
                  value: 'B',
                  child: Text('Cabang B'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedBranch = value;
                  _loadShifts();
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Shift>>(
              future: _shiftsFuture,
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
                      child: Text(
                        'Gagal memuat jadwal:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final shifts = snapshot.data ?? [];

                if (shifts.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refreshShifts,
                    child: ListView(
                      children: const [
                        SizedBox(height: 150),
                        Center(
                          child: Text('Belum ada jadwal shift.'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshShifts,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    itemCount: shifts.length,
                    itemBuilder: (context, index) {
                      final shift = shifts[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(shift.branch),
                          ),
                          title: Text(shift.employeeName),
                          subtitle: Text(
                            '${shift.employeeCode} • ${shift.position}\n'
                            '${shift.branchName}\n'
                            '${shift.shiftDate} • ${shift.formattedTime}',
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
