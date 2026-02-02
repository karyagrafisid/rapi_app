import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:rapi_app/models/rab_detail.dart';
import 'package:rapi_app/services/rab_service.dart';
import 'package:rapi_app/services/image_compress_service.dart';
import 'package:rapi_app/widgets/create_rab_detail_modal.dart'; // Import for CurrencyInputFormatter

class ShoppingModal extends StatefulWidget {
  final RabDetail detail;

  const ShoppingModal({super.key, required this.detail});

  @override
  State<ShoppingModal> createState() => _ShoppingModalState();
}

class _ShoppingModalState extends State<ShoppingModal> {
  final _formKey = GlobalKey<FormState>();
  final RabService _rabService = RabService();
  bool _isLoading = false;

  late TextEditingController _tanggalController;
  late TextEditingController _hargaBeliController;
  File? _notaFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tanggalController = TextEditingController(
      text:
          widget.detail.tanggalBelanja ??
          DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    _hargaBeliController = TextEditingController(
      text: widget.detail.hargaBeli != null
          ? NumberFormat.currency(
              locale: 'id',
              symbol: '',
              decimalDigits: 0,
            ).format(widget.detail.hargaBeli)
          : '',
    );
  }

  @override
  void dispose() {
    _tanggalController.dispose();
    _hargaBeliController.dispose();
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
                  Navigator.pop(context); // Close the sheet
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
      // Handle permission errors or other cancellations
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        String cleanHarga = _hargaBeliController.text.replaceAll(
          RegExp(r'[^0-9]'),
          '',
        );

        Map<String, String> data = {
          'tanggal_belanja': _tanggalController.text,
          'harga_beli': cleanHarga,
        };

        await _rabService.updateRabDetailWithFile(
          widget.detail.id,
          data,
          _notaFile,
        );

        if (mounted) {
          Navigator.pop(context, true); // Success
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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Update Belanja',
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

              // Tanggal Belanja
              GestureDetector(
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      _tanggalController.text = DateFormat(
                        'yyyy-MM-dd',
                      ).format(picked);
                    });
                  }
                },
                child: AbsorbPointer(
                  child: _buildTextField(
                    'Tanggal Belanja',
                    'Pilih tanggal',
                    _tanggalController,
                    icon: Icons.calendar_today,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Harga Belanja
              _buildTextField(
                'Harga Belanja',
                '0',
                _hargaBeliController,
                prefix: 'Rp. ',
                inputType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                ],
              ),
              const SizedBox(height: 16),

              // Upload Nota
              const Text(
                'Upload Nota',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B1546),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6F8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.upload_file, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _notaFile != null
                              ? _notaFile!.path.split('/').last
                              : (widget.detail.fotoNota != null
                                    ? 'Nota sudah ada (Klik ubah)'
                                    : 'Pilih file...'),
                          style: TextStyle(
                            color: _notaFile != null
                                ? Colors.black
                                : Colors.grey[600],
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
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text(
                          'Simpan Belanja',
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
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    String? prefix,
    IconData? icon,
    int maxLines = 1,
    TextInputType inputType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0B1546),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: inputType,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          validator: (value) {
            if (value == null || value.isEmpty) {
              if (label == 'Harga Belanja' || label == 'Tanggal Belanja') {
                return '$label wajib diisi';
              }
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            prefixText: prefix,
            suffixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
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
        ),
      ],
    );
  }
}
