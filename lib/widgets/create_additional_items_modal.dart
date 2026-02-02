import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:rapi_app/services/rab_service.dart';
import 'package:rapi_app/services/image_compress_service.dart';
import 'package:rapi_app/widgets/create_rab_detail_modal.dart';

class CreateAdditionalItemsModal extends StatefulWidget {
  final int rabId;

  const CreateAdditionalItemsModal({super.key, required this.rabId});

  @override
  State<CreateAdditionalItemsModal> createState() =>
      _CreateAdditionalItemsModalState();
}

class _CreateAdditionalItemsModalState
    extends State<CreateAdditionalItemsModal> {
  final RabService _rabService = RabService();
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // Controllers
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _volumeController = TextEditingController();
  final TextEditingController _satuanController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();
  final TextEditingController _tanggalController = TextEditingController(
    text: DateFormat('dd/MM/yyyy').format(DateTime.now()),
  );

  String _selectedPriority = 'Rendah';
  DateTime _selectedDate = DateTime.now();
  File? _notaFile;

  @override
  void dispose() {
    _namaController.dispose();
    _volumeController.dispose();
    _satuanController.dispose();
    _hargaController.dispose();
    _keteranganController.dispose();
    _tanggalController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _processImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _processImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        File originalFile = File(image.path);
        File? compressedFile = await ImageCompressService.compressImage(
          originalFile,
        );

        setState(() {
          _notaFile = compressedFile ?? originalFile;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _tanggalController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (_namaController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nama Item wajib diisi')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String cleanHarga = _hargaController.text.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );

      // Construct payload for single item, but wrapped in list as service expects
      List<Map<String, dynamic>> payload = [
        {
          'nama_item': _namaController.text,
          'volume': double.tryParse(_volumeController.text) ?? 0,
          'satuan': _satuanController.text,
          'harga_satuan': double.tryParse(cleanHarga) ?? 0,
          'harga_beli': double.tryParse(cleanHarga) ?? 0,
          'keterangan': _keteranganController.text,
          'prioritas': _selectedPriority,
          'tanggal_belanja': DateFormat('yyyy-MM-dd').format(_selectedDate),
        },
      ];

      await _rabService.createAdditionalRabItems(
        widget.rabId,
        payload,
        _notaFile,
      );

      if (mounted) {
        Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Item Tambahan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B1546),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Nama Item
            _buildLabel('Nama Item'),
            _buildTextField(
              controller: _namaController,
              hint: 'Masukkan nama item',
            ),
            const SizedBox(height: 16),

            // Volume & Satuan
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Volume'),
                      _buildTextField(
                        controller: _volumeController,
                        hint: '0',
                        inputType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Satuan'),
                      _buildTextField(
                        controller: _satuanController,
                        hint: 'Unit, Pcs',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tanggal
            _buildLabel('Tanggal'),
            GestureDetector(
              onTap: _selectDate,
              child: AbsorbPointer(
                child: _buildTextField(
                  controller: _tanggalController,
                  hint: 'dd/mm/yyyy',
                  suffixIcon: Icons.calendar_today_outlined,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Harga Belanja
            _buildLabel('Harga Belanja'),
            _buildTextField(
              controller: _hargaController,
              hint: '0',
              prefix: 'Rp. ',
              inputType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
              ],
            ),
            const SizedBox(height: 16),

            // Prioritas
            _buildLabel('Prioritas'),
            Row(
              children: [
                _buildPriorityButton('Rendah'),
                const SizedBox(width: 8),
                _buildPriorityButton('Sedang'),
                const SizedBox(width: 8),
                _buildPriorityButton('Tinggi'),
              ],
            ),
            const SizedBox(height: 16),

            // Keterangan
            _buildLabel('Keterangan'),
            _buildTextField(
              controller: _keteranganController,
              hint: 'Tambahkan keterangan...',
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Upload Nota
            _buildLabel('Upload Nota (Opsional)'),
            InkWell(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.transparent),
                ),
                child: Row(
                  children: [
                    Icon(Icons.upload_file, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _notaFile != null
                            ? _notaFile!.path.split('/').last
                            : 'Pilih file...',
                        style: TextStyle(
                          color: _notaFile != null
                              ? Colors.black
                              : Colors.grey[400],
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
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
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Simpan Item Tambahan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0B1546),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hint,
    String? prefix,
    IconData? suffixIcon,
    TextInputType inputType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixText: prefix,
        prefixStyle: const TextStyle(color: Colors.black, fontSize: 14),
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, color: Colors.black, size: 20)
            : null,
        filled: true,
        fillColor: const Color(0xFFF5F6F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildPriorityButton(String label) {
    bool isSelected = _selectedPriority == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPriority = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0B1546)
                : const Color(0xFFEBEBEB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
