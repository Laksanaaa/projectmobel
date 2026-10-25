import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/employee.dart';
import '../models/shift.dart';
import '../services/employee_service.dart';
import '../services/shift_service.dart';

class ShiftsPage extends StatefulWidget {
  final AppUser user;

  const ShiftsPage({super.key, required this.user});

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
      _weekStart = _weekStart.add(Duration(days: 7 * numberOfWeeks));
    });
  }

  Future<void> _showAddShiftDialog() async {
    if (!_isManager) return;

    List<Employee> employees;

    try {
      employees = await _employeeService.getEmployees();
      employees = employees.where((e) => e.isActive).toList();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil karyawan: $e')));
      return;
    }

    if (!mounted) return;

    if (employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada karyawan aktif. Tambahkan karyawan dahulu.'),
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
        const primaryBrown = Color(0xFF8C5E3C);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Tambah Jadwal Shift',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih Karyawan',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: selectedEmployeeId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFEFE8E1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFEFE8E1),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      hint: const Text('Pilih karyawan'),
                      items: employees.map((employee) {
                        return DropdownMenuItem<int>(
                          value: employee.id,
                          child: Text(
                            '${employee.employeeCode} - ${employee.fullName}',
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
                    const Text(
                      'Pilih Cabang',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedBranch,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFEFE8E1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFEFE8E1),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
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
                    const Text(
                      'Tanggal Shift',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.calendar_month_rounded,
                          color: primaryBrown,
                        ),
                        label: Text(
                          _formatDate(selectedDate),
                          style: const TextStyle(color: Colors.black87),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFEFE8E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2025),
                                  lastDate: DateTime(2035),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: primaryBrown,
                                          onPrimary: Colors.white,
                                          onSurface: Colors.black87,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    selectedDate = picked;
                                  });
                                }
                              },
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Jam kerja ditentukan otomatis berdasarkan cabang.',
                      style: TextStyle(fontSize: 11, color: Colors.black45),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
                ElevatedButton(
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
                          setDialogState(() => isSaving = true);
                          try {
                            await _shiftService.addShift(
                              employeeId: selectedEmployeeId!,
                              branch: selectedBranch,
                              shiftDate: date,
                            );
                            if (dialogContext.mounted)
                              Navigator.pop(dialogContext, true);
                          } catch (e) {
                            if (!dialogContext.mounted) return;
                            setDialogState(() => isSaving = false);
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceFirst('Exception: ', ''),
                                ),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBrown,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
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
        const SnackBar(content: Text('Jadwal shift berhasil ditambahkan.')),
      );
    }
  }

  Widget _buildBranchSchedule(String branch, List<Shift> shifts) {
    final branchName = branch == 'A' ? 'Cabang A' : 'Cabang B';
    final shiftTime = branch == 'A' ? '18.00–01.00' : '19.30–03.30';
    const primaryBrown = Color(0xFF8C5E3C);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F5F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEFE8E1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    branch,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryBrown,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    branchName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  shiftTime,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (shifts.isEmpty)
              const Text(
                'Belum ada karyawan yang dijadwalkan.',
                style: TextStyle(fontSize: 12, color: Colors.black45),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: shifts.map((shift) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEFE8E1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 14,
                          color: primaryBrown,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          shift.employeeName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
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
      final sameWeek =
          !normalizedDate.isBefore(_weekStart) &&
          normalizedDate.isBefore(weekEnd);
      final sameBranch =
          _selectedBranch == 'Semua' || shift.branch == _selectedBranch;
      return sameWeek && sameBranch;
    }).toList();

    return RefreshIndicator(
      color: const Color(0xFF8C5E3C),
      onRefresh: _refreshShifts,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
        children: [
          if (weekShifts.isEmpty)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Belum ada jadwal shift pada minggu ini.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ),
          for (final date in weekDates)
            Builder(
              builder: (context) {
                final dateShifts = weekShifts
                    .where((shift) => shift.shiftDate == _dateKey(date))
                    .toList();
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _dayName(date.weekday),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Text(
                              _formatDate(date),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFF0F0F0)),
                        const SizedBox(height: 16),
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
    const lightBg = Color(0xFFFAFAFA);
    const primaryBrown = Color(0xFF8C5E3C);

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: lightBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Jadwal Shift',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refreshShifts,
            icon: const Icon(Icons.refresh_rounded, color: Colors.black87),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      floatingActionButton: _isManager
          ? FloatingActionButton.extended(
              onPressed: _showAddShiftDialog,
              backgroundColor: primaryBrown,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Tambah Jadwal',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Jadwal Mingguan',
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(_weekStart)} – ${_formatDate(_weekStart.add(const Duration(days: 6)))}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _changeWeek(-1),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFEFE8E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: const Icon(
                          Icons.chevron_left_rounded,
                          color: primaryBrown,
                        ),
                        label: const Text(
                          'Sebelumnya',
                          style: TextStyle(color: primaryBrown),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _changeWeek(1),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFEFE8E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: const Icon(
                          Icons.chevron_right_rounded,
                          color: primaryBrown,
                        ),
                        label: const Text(
                          'Berikutnya',
                          style: TextStyle(color: primaryBrown),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedBranch,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelText: 'Filter Cabang',
                labelStyle: const TextStyle(color: Colors.black54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFEFE8E1)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(16),
              items: const [
                DropdownMenuItem(value: 'Semua', child: Text('Semua Cabang')),
                DropdownMenuItem(value: 'A', child: Text('Cabang A')),
                DropdownMenuItem(value: 'B', child: Text('Cabang B')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedBranch = value);
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Shift>>(
              future: _shiftsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryBrown),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Gagal memuat jadwal:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54),
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
