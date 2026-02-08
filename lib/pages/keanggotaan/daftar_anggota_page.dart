import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk InputFormatter
import 'package:intl/intl.dart';
// UBAH: Gunakan ApiService
import '../../services/api_service.dart';
import 'detail_anggota_page.dart';

class DaftarAnggotaPage extends StatefulWidget {
  const DaftarAnggotaPage({super.key});

  @override
  State<DaftarAnggotaPage> createState() => _DaftarAnggotaPageState();
}

class _DaftarAnggotaPageState extends State<DaftarAnggotaPage> {
  // UBAH: Inisialisasi ApiService menggantikan DbHelper
  final ApiService _apiService = ApiService();

  // --- State Utama Halaman ---
  // UBAH: Tipe data jadi List<dynamic> karena data dari JSON
  List<dynamic> _allNasabah = [];
  List<dynamic> _filteredNasabah = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // --- State & Controller untuk Form Bottom Sheet ---
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _teleponController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _namaPemilikRekeningController =
      TextEditingController();
  final TextEditingController _nomorRekeningController =
      TextEditingController();
  final TextEditingController _bankManualController = TextEditingController();

  bool _formIsLoading = false;
  bool _tambahRekening = false;
  String? _bankTerpilih;

  final List<String> _daftarBank = [
    'BCA',
    'MANDIRI',
    'BNI',
    'BRI',
    'BSI',
    'Lainnya'
  ];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  // --- FUNGSI LOAD DATA (ONLINE) ---
  Future<void> _refreshData() async {
    setState(() => _isLoading = true);

    try {
      // UBAH: Ambil data dari API Server
      final data = await _apiService.getAllAnggota();

      if (mounted) {
        setState(() {
          _allNasabah = data;
          _filteredNasabah = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Opsional: Kosongkan list jika gagal load
          _allNasabah = [];
          _filteredNasabah = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal memuat data: Koneksi bermasalah'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- FUNGSI SEARCH ---
  void _filterSearch(String query) {
    setState(() {
      _filteredNasabah = _allNasabah.where((nasabah) {
        // Tambahkan null safety check (?? '') karena data dari server bisa null
        final nama = nasabah['nama']?.toString().toLowerCase() ?? '';
        final nik = nasabah['nik']?.toString().toLowerCase() ?? '';
        final searchLower = query.toLowerCase();

        return nama.contains(searchLower) || nik.contains(searchLower);
      }).toList();
    });
  }

  // --- HELPER FORMATTING ---
  String _capitalize(String value) {
    if (value.trim().isEmpty) return "";
    return value.split(' ').map((word) {
      if (word.isEmpty) return "";
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // --- LOGIKA SIMPAN DATA (ONLINE) ---
  void _simpanNasabah(StateSetter setStateSheet) async {
    if (!_formKey.currentState!.validate() || _formIsLoading) return;

    setStateSheet(() => _formIsLoading = true);

    String finalNik = _nikController.text.trim();

    // LOGIKA PERTAHANAN: Jika NIK kosong, generate otomatis
    if (finalNik.isEmpty) {
      finalNik = "TMP-${DateTime.now().millisecondsSinceEpoch}";
    }

    String namaBank = _bankTerpilih == 'Lainnya'
        ? _capitalize(_bankManualController.text.trim())
        : (_bankTerpilih ?? '-');

    String infoRekening = "";
    if (_tambahRekening) {
      infoRekening =
          "$namaBank | ${_nomorRekeningController.text} a/n ${_capitalize(_namaPemilikRekeningController.text)}";
    }

    Map<String, dynamic> dataNasabah = {
      'nik': finalNik.toUpperCase(),
      'nama': _capitalize(_namaController.text.trim()),
      'telepon': _teleponController.text.trim(),
      'alamat': _capitalize(_alamatController.text.trim()),
      'rekening_bank': infoRekening,
      'status': 'Aktif',
      'tgl_daftar': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    };

    try {
      // UBAH: Panggil API Service untuk insert ke Server
      final success = await _apiService.insertAnggota(dataNasabah);

      if (success) {
        if (mounted) {
          Navigator.pop(context); // Tutup Bottom Sheet
          _refreshData(); // Refresh List dari Server
          _resetForm(); // Bersihkan Form

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Nasabah Berhasil Didaftarkan ke Server!'),
                backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception("Gagal menyimpan ke server");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal menyimpan: Cek koneksi internet'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        try {
          setStateSheet(() => _formIsLoading = false);
        } catch (e) {}
      }
    }
  }

  void _resetForm() {
    _nikController.clear();
    _namaController.clear();
    _teleponController.clear();
    _alamatController.clear();
    _namaPemilikRekeningController.clear();
    _nomorRekeningController.clear();
    _bankManualController.clear();
    _tambahRekening = false;
    _bankTerpilih = null;
    _formIsLoading = false;
  }

  Color _getStatusColor(String? status) {
    // Update terima nullable string
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

  // --- BOTTOM SHEET FORM ---
  void _showTambahAnggotaSheet() {
    _resetForm();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateSheet) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // --- HEADER SHEET ---
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Tambah Anggota Baru",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                  ),

                  // --- FORM SCROLLABLE ---
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // SECTION 1: DATA DIRI
                            _buildSectionTitle("Informasi Pribadi"),
                            Card(
                              elevation: 0,
                              color: Colors.grey[50],
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side:
                                      BorderSide(color: Colors.grey.shade300)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _nikController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly
                                      ],
                                      // TIDAK ADA VALIDATOR AGAR BOLEH KOSONG (Auto Generate)
                                      decoration: _inputDecoration(
                                          'NIK', Icons.credit_card,
                                          hint:
                                              'Kosongkan jika belum ada (Auto)'),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _namaController,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      decoration: _inputDecoration(
                                          'Nama Lengkap *', Icons.person),
                                      onChanged: (value) {
                                        if (_tambahRekening) {
                                          setStateSheet(() {
                                            _namaPemilikRekeningController
                                                .text = value;
                                          });
                                        }
                                      },
                                      validator: (value) =>
                                          value!.isEmpty ? 'Wajib diisi' : null,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _teleponController,
                                      keyboardType: TextInputType.phone,
                                      decoration: _inputDecoration(
                                          'Nomor Telepon / WA', Icons.phone),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _alamatController,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      maxLines: 2,
                                      decoration: _inputDecoration(
                                          'Alamat Lengkap', Icons.home),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // SECTION 2: DATA BANK
                            _buildSectionTitle("Informasi Rekening Bank"),
                            Card(
                              elevation: 0,
                              color: Colors.grey[50],
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side:
                                      BorderSide(color: Colors.grey.shade300)),
                              child: Column(
                                children: [
                                  SwitchListTile(
                                    title: const Text('Tambah Rekening Bank?',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                    value: _tambahRekening,
                                    activeColor: const Color(0xFF2E7D32),
                                    onChanged: (bool value) {
                                      setStateSheet(() {
                                        _tambahRekening = value;
                                        if (value) {
                                          _namaPemilikRekeningController.text =
                                              _namaController.text;
                                        }
                                      });
                                    },
                                  ),
                                  if (_tambahRekening)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 0, 16, 16),
                                      child: Column(
                                        children: [
                                          const Divider(),
                                          const SizedBox(height: 10),
                                          TextFormField(
                                            controller:
                                                _namaPemilikRekeningController,
                                            textCapitalization:
                                                TextCapitalization.words,
                                            decoration: _inputDecoration(
                                                'Atas Nama', Icons.badge),
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                flex: 4,
                                                child: DropdownButtonFormField<
                                                    String>(
                                                  value: _bankTerpilih,
                                                  isExpanded: true,
                                                  decoration: _inputDecoration(
                                                      'Bank',
                                                      Icons
                                                          .account_balance_wallet),
                                                  items: _daftarBank
                                                      .map((String bank) {
                                                    return DropdownMenuItem<
                                                            String>(
                                                        value: bank,
                                                        child: Text(bank,
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        14)));
                                                  }).toList(),
                                                  onChanged: (value) {
                                                    setStateSheet(() =>
                                                        _bankTerpilih = value);
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                flex: 5,
                                                child: TextFormField(
                                                  controller:
                                                      _nomorRekeningController,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .digitsOnly
                                                  ],
                                                  decoration: _inputDecoration(
                                                      'No. Rekening', null),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (_bankTerpilih == 'Lainnya') ...[
                                            const SizedBox(height: 16),
                                            TextFormField(
                                              controller: _bankManualController,
                                              textCapitalization:
                                                  TextCapitalization.words,
                                              decoration: _inputDecoration(
                                                  'Nama Bank Lainnya',
                                                  Icons.edit_note),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            SizedBox(
                                height:
                                    MediaQuery.of(context).viewInsets.bottom +
                                        20),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // --- FOOTER BUTTON ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 5,
                            offset: const Offset(0, -2))
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _formIsLoading
                            ? null
                            : () => _simpanNasabah(setStateSheet),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: _formIsLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.cloud_upload), // Icon Cloud
                        label: Text(
                          _formIsLoading ? 'MENYIMPAN...' : 'SIMPAN KE SERVER',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData? icon,
      {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon:
          icon != null ? Icon(icon, size: 20, color: Colors.grey[600]) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      isDense: true,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
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
            : const Text('Anggota (Online)'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _filteredNasabah = _allNasabah;
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          if (!_isSearching)
            IconButton(
                icon: const Icon(Icons.refresh), onPressed: _refreshData),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showTambahAnggotaSheet,
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text("Tambah Anggota",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  itemBuilder: (context, index) =>
                      _buildNasabahCard(_filteredNasabah[index]),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _isSearching
                ? 'Nasabah tidak ditemukan'
                : 'Belum ada data di Server',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildNasabahCard(dynamic nasabah) {
    // Pakai dynamic untuk handle JSON
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailAnggotaPage(nasabah: nasabah),
          ),
        ).then((_) => _refreshData());
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
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFFE8F5E9),
              child: Text(
                (nasabah['nama'] != null && nasabah['nama'].isNotEmpty)
                    ? nasabah['nama'][0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nasabah['nama'] ?? '-',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('NIK: ${nasabah['nik'] ?? '-'}',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 13)),
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
              child: Text(nasabah['status'] ?? 'Aktif',
                  style: TextStyle(
                      color: _getStatusColor(nasabah['status']),
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
