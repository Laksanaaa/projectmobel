import 'dart:convert';

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
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _shiftRateController = TextEditingController();
  final _hireDateController = TextEditingController();

  final EmployeeService _employeeService = EmployeeService();

  String _position = 'Barista';
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8C5E3C),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null && mounted) {
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

    if (shiftRate == null || !shiftRate.isFinite || shiftRate < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gaji per shift harus berupa angka yang valid.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
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
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        shiftRate: shiftRate,
        hireDate: _hireDateController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Karyawan dan akun login berhasil dibuat.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
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
          onPressed: () => Navigator.pop(context, false),
        ),
        title: const Text(
          'Tambah Karyawan',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
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
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9F5F2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add_rounded,
                        size: 42,
                        color: primaryBrown,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Data Karyawan Baru',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Lengkapi data karyawan dan akun yang akan digunakan untuk login. Kode karyawan dibuat otomatis oleh sistem.',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildSectionTitle('Data Pribadi'),
                  _buildLabel('Nama Lengkap'),
                  TextFormField(
                    controller: _fullNameController,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 100,
                    decoration: _inputDecoration(
                      hint: 'Contoh: Andi Pratama',
                      icon: Icons.person_outline_rounded,
                    ).copyWith(counterText: ''),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'Nama lengkap wajib diisi.';
                      if (value.trim().length > 100)
                        return 'Nama maksimal 100 karakter.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Nomor Telepon'),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 20,
                    decoration: _inputDecoration(
                      hint: 'Contoh: 081234567890',
                      icon: Icons.phone_outlined,
                    ).copyWith(counterText: ''),
                    validator: (value) {
                      final phone = value?.trim() ?? '';
                      if (phone.isNotEmpty &&
                          !RegExp(r'^[0-9+\-\s()]+$').hasMatch(phone)) {
                        return 'Format nomor telepon tidak valid.';
                      }
                      if (phone.length > 20)
                        return 'Nomor telepon maksimal 20 karakter.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  _buildSectionTitle('Akun Login'),
                  _buildLabel('Username'),
                  TextFormField(
                    controller: _usernameController,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    maxLength: 50,
                    decoration: _inputDecoration(
                      hint: 'Contoh: andi.barista',
                      icon: Icons.account_circle_outlined,
                    ).copyWith(counterText: ''),
                    validator: (value) {
                      final username = value?.trim() ?? '';
                      if (username.isEmpty) return 'Username wajib diisi.';
                      if (username.length < 3)
                        return 'Username minimal 3 karakter.';
                      if (username.length > 50)
                        return 'Username maksimal 50 karakter.';
                      if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(username)) {
                        return 'Gunakan huruf, angka, titik, garis bawah, atau tanda hubung.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Password'),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.next,
                    decoration:
                        _inputDecoration(
                          hint: 'Minimal 8 karakter',
                          icon: Icons.lock_outline_rounded,
                        ).copyWith(
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Tampilkan password'
                                : 'Sembunyikan password',
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.black45,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                    validator: (value) {
                      final password = value ?? '';
                      if (password.isEmpty) return 'Password wajib diisi.';
                      if (password.length < 8)
                        return 'Password minimal 8 karakter.';
                      if (utf8.encode(password).length > 72)
                        return 'Password terlalu panjang.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Simpan informasi login ini dengan aman dan berikan kepada karyawan yang bersangkutan.',
                    style: TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                  const SizedBox(height: 28),

                  _buildSectionTitle('Informasi Pekerjaan'),
                  _buildLabel('Jabatan'),
                  DropdownButtonFormField<String>(
                    initialValue: _position,
                    decoration: _inputDecoration(
                      hint: 'Pilih jabatan',
                      icon: Icons.work_outline_rounded,
                    ),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    items: const [
                      DropdownMenuItem(
                        value: 'Barista',
                        child: Text('Barista'),
                      ),
                      DropdownMenuItem(value: 'Kasir', child: Text('Kasir')),
                      DropdownMenuItem(
                        value: 'Supervisor',
                        child: Text('Supervisor'),
                      ),
                      DropdownMenuItem(
                        value: 'Manager',
                        child: Text('Manager'),
                      ),
                    ],
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() {
                                _position = value;
                              });
                            }
                          },
                  ),
                  const SizedBox(height: 16),

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
                      if (value == null || value.trim().isEmpty)
                        return 'Gaji per shift wajib diisi.';
                      final amount = double.tryParse(
                        value.trim().replaceAll(',', '.'),
                      );
                      if (amount == null || !amount.isFinite || amount < 0) {
                        return 'Masukkan nominal yang valid.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Tanggal Masuk'),
                  TextFormField(
                    controller: _hireDateController,
                    readOnly: true,
                    decoration:
                        _inputDecoration(
                          hint: 'Pilih tanggal masuk',
                          icon: Icons.calendar_month_outlined,
                        ).copyWith(
                          suffixIcon: const Icon(
                            Icons.date_range_rounded,
                            color: Colors.black45,
                          ),
                        ),
                    onTap: _isLoading ? null : _selectHireDate,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'Tanggal masuk wajib dipilih.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
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
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        _isLoading ? 'Menyimpan...' : 'Simpan Karyawan',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBrown,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        disabledBackgroundColor: primaryBrown.withValues(
                          alpha: 0.6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFEFE8E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF8C5E3C),
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
          fontSize: 13,
          color: Colors.black87,
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
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.black45, size: 22),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEFE8E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF8C5E3C), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
