import 'package:flutter/material.dart';
import '../../data/db_helper.dart';
import 'detail_anggota_page.dart';

class DaftarAnggotaPage extends StatefulWidget {
  const DaftarAnggotaPage({super.key});

  @override
  State<DaftarAnggotaPage> createState() => _DaftarAnggotaPageState();
}

class _DaftarAnggotaPageState extends State<DaftarAnggotaPage> {
  final DbHelper _dbHelper = DbHelper();

  List<Map<String, dynamic>> _allNasabah = [];
  List<Map<String, dynamic>> _filteredNasabah = [];

  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() async {
    setState(() => _isLoading = true);
    final data = await _dbHelper.getAllAnggota();
    setState(() {
      _allNasabah = data;
      _filteredNasabah = data; // Awalnya tampilkan semua
      _isLoading = false;
    });
  }

  // Fungsi Filter Pencarian
  void _filterSearch(String query) {
    setState(() {
      _filteredNasabah = _allNasabah
          .where((nasabah) =>
              nasabah['nama'].toLowerCase().contains(query.toLowerCase()) ||
              nasabah['nik'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Aktif':
        return Colors.green.shade700;
      case 'Suspend':
        return Colors.orange.shade700;
      case 'Blok':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        // Judul berubah menjadi TextField saat mode pencarian aktif
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Cari Nama atau NIK...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: _filterSearch,
              )
            : const Text('Daftar Anggota'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _filteredNasabah = _allNasabah; // Reset list
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshData,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredNasabah.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _filteredNasabah.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final nasabah = _filteredNasabah[index];
                    return _buildNasabahCard(nasabah);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _isSearching ? 'Nasabah tidak ditemukan' : 'Belum ada data nasabah',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildNasabahCard(Map<String, dynamic> nasabah) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailAnggotaPage(nasabah: nasabah),
          ),
        ).then((_) {
          // Tetap di mode pencarian jika sebelumnya sedang mencari
          _refreshData();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFFE8F5E9),
              child: Text(
                nasabah['nama'][0].toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nasabah['nama'],
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${nasabah['nik']}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(nasabah['status']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getStatusColor(nasabah['status'])),
              ),
              child: Text(
                nasabah['status'],
                style: TextStyle(
                  color: _getStatusColor(nasabah['status']),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
