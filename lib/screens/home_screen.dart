import 'package:flutter/material.dart';
import 'package:rapi_app/models/rab.dart';
import 'package:rapi_app/screens/detail_screen.dart';
import 'package:rapi_app/screens/setting_screen.dart';
import 'package:rapi_app/services/auth_service.dart';
import 'package:rapi_app/services/rab_service.dart';
import 'package:rapi_app/widgets/create_rab_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final RabService _rabService = RabService();
  final AuthService _authService = AuthService();

  // Data State
  List<Rab> _allRabs = [];
  List<Rab> _filteredRabs = [];

  // Pagination State
  int _currentPage = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  // User Data State
  String _userName = '';
  String _userJob = '';
  String? _userPhoto;

  @override
  void initState() {
    super.initState();
    _loadData(refresh: true);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _authService.getUser();
    if (user != null) {
      setState(() {
        _userName = user['nama_lengkap'] ?? user['username'] ?? 'User';
        _userJob = user['jabatan'] ?? '-';
        _userPhoto = user['foto'];
      });
    }
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasMoreData = true;
        _allRabs = [];
        _filteredRabs = [];
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final rabs = await _rabService.fetchRabs(page: _currentPage);

      setState(() {
        if (refresh) {
          _allRabs = rabs;
        } else {
          _allRabs.addAll(rabs);
        }

        // Re-apply filter if search is active
        _filterRabs(_searchController.text);

        // Check if we reached the end (less than 10 means last page)
        if (rabs.length < 10) {
          _hasMoreData = false;
        }

        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_isLoadingMore && _hasMoreData) {
      _currentPage++;
      await _loadData(refresh: false);
    }
  }

  Future<void> _refreshList() async {
    await _loadData(refresh: true);
  }

  void _filterRabs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredRabs = List.from(_allRabs);
      } else {
        _filteredRabs = _allRabs
            .where(
              (rab) => rab.namaRab.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  void _showProfileModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildProfileModal(),
    ).then((_) {
      _loadUserData();
    });
  }

  void _showCreateRabModal() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateRabModal(),
    );

    if (result == true) {
      _refreshList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB), // Light greyish background
      body: Stack(
        children: [
          // Content
          Positioned.fill(
            bottom: 80, // Space for footer
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Logo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
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
                ),
                const SizedBox(height: 30),
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0xFF3D4C74),
                      ), // Dark blue border
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterRabs,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: 'cari RAB..',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // RAB List with "Load More"
                Expanded(
                  child: _isLoading && _allRabs.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _refreshList,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            children: [
                              ..._filteredRabs
                                  .map((rab) => _buildRabCard(rab))
                                  .toList(),

                              if (_hasMoreData &&
                                  _searchController.text.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  child: _isLoadingMore
                                      ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : SizedBox(
                                          width: double.infinity,
                                          height: 48,
                                          child: ElevatedButton(
                                            onPressed: _loadMore,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: const Color(
                                                0xFF0B1546,
                                              ),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                side: const BorderSide(
                                                  color: Color(0xFF0B1546),
                                                ),
                                              ),
                                            ),
                                            child: const Text(
                                              'Tampilkan Lebih',
                                            ),
                                          ),
                                        ),
                                ),

                              if (!_hasMoreData && _allRabs.isNotEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Center(
                                    child: Text(
                                      "Semua data telah dimuat",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),

                              // Check if empty
                              if (_filteredRabs.isEmpty && !_isLoading)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 50.0),
                                    child: Text("Tidak ada RAB ditemukan"),
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
          // Footer
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomNav()),
        ],
      ),
    );
  }

  Widget _buildRabCard(Rab rab) {
    // Status Styles
    LinearGradient badgeGradient;
    Color badgeText = Colors.black;

    switch (rab.status.toLowerCase()) {
      case 'disetujui':
        badgeGradient = const LinearGradient(
          colors: [Color(0xFFA5F3CD), Color(0xFF6EE7B7)],
        );
        badgeText = const Color(0xFF064E3B);
        break;
      case 'pending':
        badgeGradient = const LinearGradient(
          colors: [Color(0xFFFDE68A), Color(0xFFFCD34D)],
        );
        badgeText = const Color(0xFF78350F);
        break;
      case 'ditolak':
        badgeGradient = const LinearGradient(
          colors: [Color(0xFFFECACA), Color(0xFFF87171)],
        );
        badgeText = const Color(0xFF7F1D1D);
        break;
      case 'selesai':
        badgeGradient = const LinearGradient(
          colors: [Color(0xFFBAE6FD), Color(0xFF7DD3FC)],
        );
        badgeText = const Color(0xFF0C4A6E);
        break;
      default:
        badgeGradient = const LinearGradient(
          colors: [Colors.grey, Colors.grey],
        );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Padding(
                padding: const EdgeInsets.only(right: 80),
                child: Text(
                  rab.namaRab.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ),
              Text(
                'periode ${rab.periode}',
                style: const TextStyle(color: Colors.black54, fontSize: 11),
              ),
              const SizedBox(height: 12),
              // Details
              _buildRichDetail('Dibuat Oleh :', rab.ttdNama1),
              _buildRichDetail(' | Disetujui 1 :', rab.ttdNama2),
              _buildRichDetail(' | Disetujui 2 :', rab.ttdNama3),
              const SizedBox(height: 8),
              _buildRichDetail(
                'Rekening Penerima Anggaran :',
                '${rab.bank} - ${rab.rekening}',
              ),
              const SizedBox(height: 20),
              // Action Buttons Row
              Row(
                children: [
                  // Isi Detail
                  Expanded(
                    child: SizedBox(
                      height: 32, // Fixed height
                      child: ElevatedButton(
                        onPressed: () async {
                          FocusScope.of(context).unfocus(); // Close keyboard
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RabDetailScreen(rab: rab),
                            ),
                          );
                          // Refresh when back from detail (in case data changed)
                          _refreshList();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B1240), // Dark Blue
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero, // Remove padding
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'item RAB',
                          style: TextStyle(fontSize: 10), // Smaller font
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Edit
                  InkWell(
                    onTap: () async {
                      final result = await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => CreateRabModal(rab: rab),
                      );
                      if (result == true) {
                        _refreshList();
                      }
                    },
                    child: _buildOutlineIcon(Icons.edit_square, Colors.blue),
                  ),
                  const SizedBox(width: 8),
                  // Delete
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Hapus RAB'),
                          content: const Text(
                            'Apakah Anda yakin ingin menghapus RAB ini?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(context); // Close dialog
                                try {
                                  await _rabService.deleteRab(rab.id);
                                  _refreshList();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Gagal menghapus: $e'),
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                'Hapus',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: _buildOutlineIcon(Icons.delete, Colors.red),
                  ),
                ],
              ),
            ],
          ),
          // Status Badge
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                gradient: badgeGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                rab.status,
                style: TextStyle(
                  color: badgeText,
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

  Widget _buildRichDetail(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black, fontSize: 10),
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const TextSpan(text: ' '),
          TextSpan(text: value),
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

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        30,
      ), // Side and bottom margins
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
              // Profile Item
              InkWell(
                onTap: _showProfileModal,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/profile.png', height: 26),
                      const SizedBox(height: 2),
                      const Text(
                        'Profile',
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
              // Settings Item
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingScreen(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/setting.png', height: 26),
                      const SizedBox(height: 2),
                      const Text(
                        'Setting',
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
            ],
          ),
          // Centered FAB
          Positioned(
            top: -25, // Pop out half height
            child: GestureDetector(
              onTap: _showCreateRabModal,
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

  Widget _buildProfileModal() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10),
              ],
            ),
            child: ClipOval(
              child: _userPhoto != null
                  ? Image.network(
                      '${AuthService.baseUrl.replaceAll('/api', '')}/storage/$_userPhoto',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/images/profile.png',
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset('assets/images/profile.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _userName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B1546),
            ),
          ),
          Text(
            _userJob,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close modal first
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[50],
                foregroundColor: const Color(0xFF0B1546),
              ),
              child: const Text('Edit Profil'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
