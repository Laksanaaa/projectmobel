
import 'package:flutter/material.dart';

import '../services/employee_service.dart';

class AddEmployeePage extends StatefulWidget {
  const AddEmployeePage({super.key});

  @override
  State<AddEmployeePage> createState() => _AddEmployeePageState();
}

class _AddEmployeePageState extends State<AddEmployeePage> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _shiftRateController = TextEditingController();
  final _hireDateController = TextEditingController();

  final EmployeeService _employeeService = EmployeeService();

  String _position = 'Barista';
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _shiftRateController.dispose();
    _hireDateController.dispose();
    super.dispose();
  }

  Future<void> _selectHireDate() async {
    final now = DateTime.now();

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year, now.month, now.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
      helpText: 'Pilih tanggal masuk karyawan',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );

    if (selectedDate != null) {
      final year = selectedDate.year.toString().padLeft(4, '0');
      final month = selectedDate.month.toString().padLeft(2, '0');
      final day = selectedDate.day.toString().padLeft(2, '0');

      setState(() {
        _hireDateController.text = '$year-$month-$day';
      });
    }
  }

  Future<void> _saveEmployee() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final shiftRate = double.tryParse(
      _shiftRateController.text.trim().replaceAll(',', '.'),
    );

    if (shiftRate == null || shiftRate < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gaji per shift harus berupa angka yang valid.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _employeeService.addEmployee(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        position: _position,
        shiftRate: shiftRate,
        hireDate: _hireDateController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Karyawan berhasil ditambahkan.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6F4E37);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Karyawan'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.person_add_alt_1,
                    size: 48,
                    color: primaryColor,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Data Karyawan Baru',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Isi informasi karyawan di bawah ini. '
                    'Kode karyawan akan dibuat otomatis oleh sistem.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nama lengkap
                  _buildLabel('Nama Lengkap'),
                  TextFormField(
                    controller: _fullNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration(
                      hint: 'Contoh: Andi Pratama',
                      icon: Icons.person_outline,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama lengkap wajib diisi.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Nomor telepon
                  _buildLabel('Nomor Telepon'),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration(
                      hint: 'Contoh: 081234567890',
                      icon: Icons.phone_outlined,
                    ),
                    validator: (value) {
                      if (value != null &&
                          value.trim().isNotEmpty &&
                          !RegExp(r'^[0-9+\-\s()]+$')
                              .hasMatch(value.trim())) {
                        return 'Format nomor telepon tidak valid.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Jabatan
                  _buildLabel('Jabatan'),
                  DropdownButtonFormField<String>(
                    initialValue: _position,
                    decoration: _inputDecoration(
                      hint: 'Pilih jabatan',
                      icon: Icons.work_outline,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Barista',
                        child: Text('Barista'),
                      ),
                      DropdownMenuItem(
                        value: 'Kasir',
                        child: Text('Kasir'),
                      ),
                      DropdownMenuItem(
                        value: 'Supervisor',
                        child: Text('Supervisor'),
                      ),
                      DropdownMenuItem(
                        value: 'Manager',
                        child: Text('Manager'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _position = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 18),

                  // Gaji per shift
                  _buildLabel('Gaji per Shift (Rp)'),
                  TextFormField(
                    controller: _shiftRateController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDecoration(
                      hint: 'Contoh: 50000',
                      icon: Icons.payments_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Gaji per shift wajib diisi.';
                      }

                      final amount = double.tryParse(
                        value.trim().replaceAll(',', '.'),
                      );

                      if (amount == null || amount < 0) {
                        return 'Masukkan nominal yang valid.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Tanggal masuk
                  _buildLabel('Tanggal Masuk'),
                  TextFormField(
                    controller: _hireDateController,
                    readOnly: true,
                    decoration: _inputDecoration(
                      hint: 'Pilih tanggal masuk',
                      icon: Icons.calendar_month_outlined,
                    ).copyWith(
                      suffixIcon: const Icon(Icons.date_range),
                    ),
                    onTap: _selectHireDate,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Tanggal masuk wajib dipilih.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Tombol simpan
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveEmployee,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _isLoading
                            ? 'Menyimpan...'
                            : 'Simpan Karyawan',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            primaryColor.withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFF6F4E37),
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    );
  }
}
