import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:rapi_app/models/rab_detail.dart';
import 'package:rapi_app/services/rab_service.dart';

class CreateRabDetailModal extends StatefulWidget {
  final int rabId;
  final RabDetail? detail; // If provided, we are in Edit mode

  const CreateRabDetailModal({super.key, required this.rabId, this.detail});

  @override
  State<CreateRabDetailModal> createState() => _CreateRabDetailModalState();
}

class _CreateRabDetailModalState extends State<CreateRabDetailModal> {
  final _formKey = GlobalKey<FormState>();
  final RabService _rabService = RabService();
  bool _isLoading = false;

  late TextEditingController _namaItemController;
  late TextEditingController _volumeController;
  late TextEditingController _satuanController;
  late TextEditingController _hargaSatuanController;
  late TextEditingController _keteranganController;
  String _prioritas = 'Sedang';

  @override
  void initState() {
    super.initState();
    _namaItemController = TextEditingController(
      text: widget.detail?.uraian ?? '',
    );
    _volumeController = TextEditingController(
      text: widget.detail?.volume.toString() ?? '',
    );
    _satuanController = TextEditingController(
      text: widget.detail?.satuan ?? '',
    );
    _hargaSatuanController = TextEditingController(
      text: widget.detail != null
          ? NumberFormat.currency(
              locale: 'id',
              symbol: '',
              decimalDigits: 0,
            ).format(widget.detail!.hargaSatuan)
          : '',
    );
    _keteranganController = TextEditingController(
      text: widget.detail?.keterangan ?? '',
    );
    if (widget.detail != null) {
      _prioritas = widget.detail!.prioritas;
    }
  }

  @override
  void dispose() {
    _namaItemController.dispose();
    _volumeController.dispose();
    _satuanController.dispose();
    _hargaSatuanController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Clean the currency string (remove non-digits)
      String cleanHarga = _hargaSatuanController.text.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );

      final data = {
        'id_rab': widget.rabId,
        'nama_item': _namaItemController.text,
        'volume': double.tryParse(_volumeController.text) ?? 0,
        'satuan': _satuanController.text,
        'harga_satuan': double.tryParse(cleanHarga) ?? 0,
        'prioritas': _prioritas,
        'keterangan': _keteranganController.text,
      };

      try {
        if (widget.detail == null) {
          await _rabService.createRabDetail(data);
        } else {
          await _rabService.updateRabDetail(widget.detail!.id, data);
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
    bool isEdit = widget.detail != null;

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
                  isEdit ? 'Edit Item RAB' : 'Tambah Item RAB',
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
                      'Nama Item',
                      'Masukkan nama item',
                      _namaItemController,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildModalField(
                            'Volume',
                            '0',
                            _volumeController,
                            type: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildModalField(
                            'Satuan',
                            'Unit, Pcs',
                            _satuanController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildModalField(
                      'Harga Satuan',
                      '0',
                      _hargaSatuanController,
                      type: TextInputType.number,
                      prefix: 'Rp. ',
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPrioritySelector(),
                    const SizedBox(height: 16),
                    _buildModalField(
                      'Keterangan',
                      'Tambahkan keterangan...',
                      _keteranganController,
                      maxLines: 3,
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
                            : Text(isEdit ? 'Simpan Perubahan' : 'Simpan Item'),
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
    String? prefix,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
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
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          validator: (value) {
            if (value == null || value.isEmpty) {
              if (label == 'Nama Item' ||
                  label == 'Volume' ||
                  label == 'Harga Satuan') {
                return '$label tidak boleh kosong';
              }
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            prefixText:
                prefix, // Use prefixText instead of prefix widget for better alignment
            fillColor: const Color(0xFFF5F6F8),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
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

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prioritas',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0B1546),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildPriorityOption('Rendah')),
            const SizedBox(width: 8),
            Expanded(child: _buildPriorityOption('Sedang')),
            const SizedBox(width: 8),
            Expanded(child: _buildPriorityOption('Tinggi')),
          ],
        ),
      ],
    );
  }

  Widget _buildPriorityOption(String label) {
    bool isSelected = _prioritas == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _prioritas = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0B1546) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    double value = double.parse(cleanText);

    final formatter = NumberFormat.currency(
      locale: 'id',
      symbol: '',
      decimalDigits: 0,
    );

    String newText = formatter.format(value);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
