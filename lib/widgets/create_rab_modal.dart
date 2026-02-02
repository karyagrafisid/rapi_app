import 'package:flutter/material.dart';
import 'package:rapi_app/models/rab.dart';
import 'package:rapi_app/services/rab_service.dart';

class CreateRabModal extends StatefulWidget {
  final Rab? rab; // If provided, we are in Edit mode

  const CreateRabModal({super.key, this.rab});

  @override
  State<CreateRabModal> createState() => _CreateRabModalState();
}

class _CreateRabModalState extends State<CreateRabModal> {
  final _formKey = GlobalKey<FormState>();
  final RabService _rabService = RabService();
  bool _isLoading = false;

  late TextEditingController _namaRabController;
  late TextEditingController _periodeController;
  late TextEditingController _jabatan1Controller;
  late TextEditingController _nama1Controller;
  late TextEditingController _jabatan2Controller;
  late TextEditingController _nama2Controller;
  late TextEditingController _jabatan3Controller;
  late TextEditingController _nama3Controller;
  late TextEditingController _bankController;
  late TextEditingController _rekeningController;

  @override
  void initState() {
    super.initState();
    _namaRabController = TextEditingController(text: widget.rab?.namaRab ?? '');
    _periodeController = TextEditingController(
      text: widget.rab?.periode.toString() ?? '2026',
    );
    _jabatan1Controller = TextEditingController(
      text: widget.rab?.ttdJabatan1 ?? '',
    );
    _nama1Controller = TextEditingController(text: widget.rab?.ttdNama1 ?? '');
    _jabatan2Controller = TextEditingController(
      text: widget.rab?.ttdJabatan2 ?? '',
    );
    _nama2Controller = TextEditingController(text: widget.rab?.ttdNama2 ?? '');
    _jabatan3Controller = TextEditingController(
      text: widget.rab?.ttdJabatan3 ?? '',
    );
    _nama3Controller = TextEditingController(text: widget.rab?.ttdNama3 ?? '');
    _bankController = TextEditingController(text: widget.rab?.bank ?? '');
    _rekeningController = TextEditingController(
      text: widget.rab?.rekening ?? '',
    );
  }

  @override
  void dispose() {
    _namaRabController.dispose();
    _periodeController.dispose();
    _jabatan1Controller.dispose();
    _nama1Controller.dispose();
    _jabatan2Controller.dispose();
    _nama2Controller.dispose();
    _jabatan3Controller.dispose();
    _nama3Controller.dispose();
    _bankController.dispose();
    _rekeningController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final data = {
        'nama_rab': _namaRabController.text,
        'periode': _periodeController.text,
        'ttd_jabatan_1': _jabatan1Controller.text,
        'ttd_nama_1': _nama1Controller.text,
        'ttd_jabatan_2': _jabatan2Controller.text,
        'ttd_nama_2': _nama2Controller.text,
        'ttd_jabatan_3': _jabatan3Controller.text,
        'ttd_nama_3': _nama3Controller.text,
        'bank': _bankController.text,
        'rekening': _rekeningController.text,
      };

      try {
        if (widget.rab == null) {
          await _rabService.createRab(data);
        } else {
          await _rabService.updateRab(widget.rab!.id, data);
        }
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.rab != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Edit RAB' : 'Buat RAB Baru',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B1546),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildModalField(
                      'Nama RAB',
                      'Masukkan nama rab',
                      _namaRabController,
                    ),
                    const SizedBox(height: 16),
                    _buildModalField(
                      'Periode',
                      '2026',
                      _periodeController,
                      type: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'Penandatangan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildModalField(
                      'Jabatan Pembuat',
                      'Contoh: Ketua Panitia',
                      _jabatan1Controller,
                    ),
                    const SizedBox(height: 16),
                    _buildModalField(
                      'Nama Pembuat',
                      'Nama lengkap & gelar',
                      _nama1Controller,
                    ),
                    const SizedBox(height: 16),
                    _buildModalField(
                      'Jabatan Menyetujui 1',
                      'Contoh: Sekretaris',
                      _jabatan2Controller,
                    ),
                    const SizedBox(height: 16),
                    _buildModalField(
                      'Nama Menyetujui 1',
                      'Nama lengkap & gelar',
                      _nama2Controller,
                    ),
                    const SizedBox(height: 16),
                    _buildModalField(
                      'Jabatan Menyetujui 2',
                      'Contoh: Bendahara',
                      _jabatan3Controller,
                    ),
                    const SizedBox(height: 16),
                    _buildModalField(
                      'Nama Menyetujui 2',
                      'Nama lengkap & gelar',
                      _nama3Controller,
                    ),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'Rekening',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildModalField(
                      'Nama Bank',
                      'Contoh: BSI',
                      _bankController,
                    ),
                    const SizedBox(height: 16),
                    _buildModalField(
                      'Nomor Rekening',
                      'Masukkan nomor rekening',
                      _rekeningController,
                      type: TextInputType.number,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B1546),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : Text(isEdit ? 'Update RAB' : 'Simpan RAB'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalField(
    String label,
    String hint,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0B1546),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: type,
          validator: (value) {
            if (value == null || value.isEmpty) {
              // Basic validation, strictness can be adjusted
              if (label == 'Nama RAB' || label == 'Periode') {
                return '$label tidak boleh kosong';
              }
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            fillColor: const Color(0xFFF5F6F8),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), // Added border radius
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
