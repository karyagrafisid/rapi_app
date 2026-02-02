import 'package:flutter/material.dart';
import 'package:rapi_app/models/rab.dart';
import 'package:rapi_app/models/rab_detail.dart';
import 'package:rapi_app/services/rab_service.dart';
import 'package:rapi_app/widgets/create_additional_items_modal.dart';
import 'package:rapi_app/widgets/create_rab_detail_modal.dart';
import 'package:rapi_app/widgets/shopping_modal.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class RabDetailScreen extends StatefulWidget {
  final Rab rab;

  const RabDetailScreen({super.key, required this.rab});

  @override
  State<RabDetailScreen> createState() => _RabDetailScreenState();
}

class _RabDetailScreenState extends State<RabDetailScreen> {
  late Rab _rab;
  final RabService _rabService = RabService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _rab = widget.rab;
    _refreshRab(); // Fetch full details since list view doesn't provide them
  }

  Future<void> _refreshRab() async {
    try {
      final updatedRab = await _rabService.getRabById(widget.rab.id);
      setState(() {
        _rab = updatedRab;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to refresh data: $e')));
    }
  }

  Future<void> _deleteItem(int detailId) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Item'),
            content: const Text('Apakah Anda yakin ingin menghapus item ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      setState(() => _isLoading = true);
      try {
        await _rabService.deleteRabDetail(detailId);
        await _refreshRab();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item berhasil dihapus')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal menghapus item: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Main Column with Fixed Header and Scrollable Body
          Column(
            children: [
              const SizedBox(height: 60), // Top spacing for status bar
              // Fixed Header Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Logo
                    Container(
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/iconrab.png',
                          height: 50,
                          width: 50,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title Section
                    Container(
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Text(
                            _rab.namaRab.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'periode ${_rab.periode}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Export Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _buildExportButton(
                            'Cetak RAB',
                            Icons.picture_as_pdf,
                            Colors.red.shade700,
                            () => _downloadPdf('rab'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildExportButton(
                            'Cetak LPJ',
                            Icons.receipt_long,
                            Colors.blue.shade900,
                            () => _downloadPdf('lpj'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Formatting divider/shadow for header separation (optional but good)
                    Container(height: 1, color: Colors.black.withOpacity(0.05)),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshRab,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Signatures
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Dibuat Oleh : ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: '${_rab.ttdNama1} | '),
                              const TextSpan(
                                text: 'Disetujui 1 : ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: '${_rab.ttdNama2} | '),
                              const TextSpan(
                                text: 'Disetujui 2 : ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: _rab.ttdNama3),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        // List Items
                        if (_rab.details.isEmpty)
                          Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(20.0),
                            child: const Text(
                              "Belum ada item RAB",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        else
                          ..._rab.details
                              .map((detail) => _buildItemCard(context, detail))
                              .toList(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),

          // Footer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNav(context),
          ),
        ],
      ),
    );
  }

  MaterialColor _getPriorityColor(String? priority) {
    if (priority == null) return Colors.grey;
    switch (priority.toLowerCase()) {
      case 'tinggi':
        return Colors.red;
      case 'sedang':
        return Colors.amber;
      case 'rendah':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  Widget _buildItemCard(BuildContext context, RabDetail detail) {
    // Determine colors based on priority
    MaterialColor badgeColor = _getPriorityColor(detail.prioritas);
    LinearGradient gradient;
    Color textColor;

    if (badgeColor == Colors.green) {
      gradient = const LinearGradient(
        colors: [Color(0xFFA5F3CD), Color(0xFF6EE7B7)],
      );
      textColor = const Color(0xFF064E3B);
    } else if (badgeColor == Colors.amber) {
      gradient = const LinearGradient(
        colors: [Color(0xFFFDE68A), Color(0xFFFCD34D)],
      );
      textColor = const Color(0xFF78350F);
    } else {
      gradient = const LinearGradient(
        colors: [Color(0xFFFECACA), Color(0xFFF87171)],
      );
      textColor = const Color(0xFF7F1D1D);
    }

    // Calculate total if 0 from DB
    double displayTotal = detail.jumlahTotal > 0
        ? detail.jumlahTotal
        : (detail.volume * detail.hargaSatuan);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: detail.isTambahan
            ? Border.all(color: Colors.orange.shade300, width: 2)
            : null,
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      detail.uraian,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Details
              Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 11, color: Colors.black),
                  children: [
                    const TextSpan(
                      text: 'Anggaran : ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                          '${detail.volume} ${detail.satuan} @ ${_formatCurrency(detail.hargaSatuan)} = ',
                    ),
                    TextSpan(
                      text: _formatCurrency(displayTotal),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 11, color: Colors.black),
                  children: [
                    const TextSpan(
                      text: 'Keterangan : ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: detail.keterangan ?? '-'),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Tanggal Belanja : ${detail.tanggalBelanja ?? '-'}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Nota Link
                  if (detail.fotoNota != null && detail.fotoNota!.isNotEmpty)
                    InkWell(
                      onTap: () => _showNotaDialog(context, detail.fotoNota!),
                      child: Text(
                        'Nota : Lihat Nota',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                          fontStyle: FontStyle.italic,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    )
                  else
                    const Text(
                      'Nota : -',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Harga Beli : ${detail.hargaBeli != null ? _formatCurrency(detail.hargaBeli!) : "-"}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.normal,
                ),
              ),

              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () => _showShoppingModal(context, detail),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B1240),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'klik belanja',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _showEditItemModal(context, detail),
                    child: _buildOutlineIcon(Icons.edit_square, Colors.blue),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _deleteItem(detail.id),
                    child: _buildOutlineIcon(Icons.delete, Colors.red),
                  ),
                ],
              ),
            ],
          ),
          // Badge Absolute
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                detail.prioritas,
                style: TextStyle(
                  color: textColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutlineIcon(IconData icon, MaterialColor color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade100),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Back/RAB Item
              InkWell(
                onTap: () {
                  Navigator.pop(context); // Go back to Home
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/rab.png', height: 26),
                      const SizedBox(height: 2),
                      const Text(
                        'RAB',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B1546),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 60), // Space for centered FAB
              // Additional Item
              InkWell(
                onTap: () => _showAdditionalItemModal(context),
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/plus-secondary.png',
                        height: 26,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Item Tambahan',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B1546),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Centered FAB
          Positioned(
            top: -25, // Pop out half height
            child: GestureDetector(
              onTap: () => _showAddItemModal(context),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0B1240).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Image.asset('assets/images/plus-primary.png'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddItemModal(BuildContext context) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateRabDetailModal(rabId: _rab.id),
    );

    if (result == true) {
      _refreshRab();
    }
  }

  void _showEditItemModal(BuildContext context, RabDetail detail) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          CreateRabDetailModal(rabId: _rab.id, detail: detail),
    );

    if (result == true) {
      _refreshRab();
    }
  }

  void _showAdditionalItemModal(BuildContext context) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateAdditionalItemsModal(rabId: _rab.id),
    );

    if (result == true) {
      _refreshRab();
    }
  }

  void _showShoppingModal(BuildContext context, RabDetail detail) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShoppingModal(detail: detail),
    );

    if (result == true) {
      _refreshRab();
    }
  }

  Future<void> _downloadPdf(String mode) async {
    setState(() => _isLoading = true);

    // Generate Secure Token: md5(id + secret)
    final bytes = utf8.encode('${_rab.id}rapi_2026');
    final token = md5.convert(bytes).toString();

    // Link: Menggunakan Public Web Route
    final webUrl = RabService.baseUrl.replaceAll('/api', '');
    final url = '$webUrl/download-pdf/${_rab.id}?mode=$mode&token=$token';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Find local directory
        final directory = await getApplicationDocumentsDirectory();
        final filename =
            '${mode.toUpperCase()}_RAB_${_rab.namaRab.replaceAll(' ', '_')}.pdf';
        final file = File('${directory.path}/$filename');

        // Write file bytes
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download ${mode.toUpperCase()} Berhasil!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'LIHAT FILE',
                textColor: Colors.white,
                onPressed: () async {
                  await OpenFilex.open(file.path);
                },
              ),
            ),
          );
        }
      } else {
        throw 'Gagal mendownload file: Server Error (${response.statusCode})';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendownload PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildExportButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        elevation: 1,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        side: BorderSide(color: color.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  void _showNotaDialog(BuildContext context, String notaPath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      '${RabService.baseUrl.replaceAll('/api', '')}/storage/$notaPath',
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          alignment: Alignment.center,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Gagal memuat gambar',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widgets that don't need significant changes...
}
