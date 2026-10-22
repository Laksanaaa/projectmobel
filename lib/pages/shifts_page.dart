
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/employee.dart';
import '../models/shift.dart';
import '../services/employee_service.dart';
import '../services/shift_service.dart';

class ShiftsPage extends StatefulWidget {
  final AppUser user;

  const ShiftsPage({
    super.key,
    required this.user,
  });

  @override
  State<ShiftsPage> createState() => _ShiftsPageState();
}

class _ShiftsPageState extends State<ShiftsPage> {
  final EmployeeService _employeeService = EmployeeService();
  final ShiftService _shiftService = ShiftService();

  late Future<List<Shift>> _shiftsFuture;

  String _selectedBranch = 'Semua';
  DateTime _weekStart = _mondayOf(DateTime.now());

  bool get _isManager => widget.user.role == UserRole.manager;

  static DateTime _mondayOf(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  String _dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _dayName(int weekday) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    return days[weekday - 1];
  }

  @override
  void initState() {
    super.initState();
    _loadShifts();
  }

  void _loadShifts() {
    _shiftsFuture = _shiftService.getShifts();
  }

  Future<void> _refreshShifts() async {
    setState(_loadShifts);
    await _shiftsFuture;
  }

  void _changeWeek(int numberOfWeeks) {
    setState(() {
      _weekStart = _weekStart.add(
        Duration(days: 7 * numberOfWeeks),
      );
    });
  }

  Future<void> _showAddShiftDialog() async {
    // Pemeriksaan role sebelum membuka dialog.
    if (!_isManager) return;

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
                      label: Text(_formatDate(selectedDate)),
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

                          final date = _dateKey(selectedDate);

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

  Widget _buildBranchSchedule(
    String branch,
    List<Shift> shifts,
  ) {
    final branchName = branch == 'A' ? 'Cabang A' : 'Cabang B';
    final shiftTime =
        branch == 'A' ? '18.00–01.00' : '19.30–03.30';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  child: Text(branch),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    branchName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  shiftTime,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (shifts.isEmpty)
              const Text(
                'Belum ada karyawan yang dijadwalkan.',
                style: TextStyle(fontSize: 13),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: shifts.map((shift) {
                  return Chip(
                    avatar: const Icon(
                      Icons.person_outline,
                      size: 18,
                    ),
                    label: Text(shift.employeeName),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySchedule(List<Shift> allShifts) {
    final weekDates = List.generate(
      7,
      (index) => _weekStart.add(Duration(days: index)),
    );

    final weekEnd = _weekStart.add(const Duration(days: 7));

    final weekShifts = allShifts.where((shift) {
      final date = DateTime.tryParse(shift.shiftDate);
      if (date == null) return false;

      final normalizedDate = DateTime(date.year, date.month, date.day);

      final sameWeek = !normalizedDate.isBefore(_weekStart) &&
          normalizedDate.isBefore(weekEnd);

      final sameBranch = _selectedBranch == 'Semua' ||
          shift.branch == _selectedBranch;

      return sameWeek && sameBranch;
    }).toList();

    return RefreshIndicator(
      onRefresh: _refreshShifts,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        children: [
          if (weekShifts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Belum ada jadwal shift pada minggu ini.',
                textAlign: TextAlign.center,
              ),
            ),
          for (final date in weekDates)
            Builder(
              builder: (context) {
                final dateShifts = weekShifts.where((shift) {
                  return shift.shiftDate == _dateKey(date);
                }).toList();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _dayName(date.weekday),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            Text(
                              _formatDate(date),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        if (_selectedBranch == 'Semua' ||
                            _selectedBranch == 'A')
                          _buildBranchSchedule(
                            'A',
                            dateShifts
                                .where((shift) => shift.branch == 'A')
                                .toList(),
                          ),
                        if (_selectedBranch == 'Semua' ||
                            _selectedBranch == 'B')
                          _buildBranchSchedule(
                            'B',
                            dateShifts
                                .where((shift) => shift.branch == 'B')
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
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
      floatingActionButton: _isManager
          ? FloatingActionButton.extended(
              onPressed: _showAddShiftDialog,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Jadwal'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _changeWeek(-1),
                  tooltip: 'Minggu sebelumnya',
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Jadwal Mingguan',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_formatDate(_weekStart)} – '
                        '${_formatDate(
                          _weekStart.add(const Duration(days: 6)),
                        )}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _changeWeek(1),
                  tooltip: 'Minggu berikutnya',
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
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

                return _buildWeeklySchedule(snapshot.data ?? []);
              },
            ),
          ),
        ],
      ),
    );
  }
}
