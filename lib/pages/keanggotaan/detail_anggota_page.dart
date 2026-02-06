import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/db_helper.dart';
import 'edit_anggota_page.dart';

// Import Halaman Detail Fasilitas
import 'detail_jual_beli_anggota_page.dart';
import 'detail_bagi_hasil_anggota_page.dart';
import 'detail_pinjaman_lunak_anggota_page.dart';
import 'detail_usaha_bersama_anggota_page.dart';

class DetailAnggotaPage extends StatefulWidget {
  final Map<String, dynamic> nasabah;

  const DetailAnggotaPage({super.key, required this.nasabah});

  @override
  State<DetailAnggotaPage> createState() => _DetailAnggotaPageState();
}

class _DetailAnggotaPageState extends State<DetailAnggotaPage> {
  final DbHelper _dbHelper = DbHelper();
  late Map<String, dynamic> _currentNasabah;
  double _saldoWadiah = 0;

  final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _currentNasabah = widget.nasabah;
    _loadSaldoWadiah();
  }

  Future<void> _loadSaldoWadiah() async {
    try {
      double saldo = await _dbHelper.getSaldoWadiah(_currentNasabah['id']);
      if (mounted) setState(() => _saldoWadiah = saldo);
    } catch (e) {
      debugPrint("Error load saldo: $e");
    }
  }

  Future<void> _refreshData() async {
    final allNasabah = await _dbHelper.getAllAnggota();
    try {
      final updatedData = allNasabah.firstWhere(
        (element) => element['id'] == _currentNasabah['id'],
      );
      setState(() => _currentNasabah = updatedData);
      await _loadSaldoWadiah();
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  // --- FUNGSI RIWAYAT MUTASI (SUDAH DIPERBAIKI SESUAI DB HELPER) ---
  void _showRiwayatMutasi() async {
    try {
      final db = await _dbHelper.database;

      // PERBAIKAN: Menggunakan nama tabel 'transaksi_wadiah' sesuai DbHelper Anda
      final List<Map<String, dynamic>> riwayat = await db.query(
        'transaksi_wadiah',
        where: 'nasabah_id = ?',
        whereArgs: [_currentNasabah['id']],
        orderBy: 'id DESC',
      );

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 5),
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),

                    // Header Title
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Riwayat Mutasi Tabungan",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("${riwayat.length} Transaksi",
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // List Data Transaksi
                    Expanded(
                      child: riwayat.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history_edu,
                                      size: 60, color: Colors.grey[300]),
                                  const SizedBox(height: 10),
                                  const Text("Belum ada riwayat transaksi.",
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              itemCount: riwayat.length,
                              separatorBuilder: (ctx, i) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final item = riwayat[index];

                                // PERBAIKAN: Menggunakan nama kolom sesuai DbHelper ('jenis', 'jumlah', 'tgl_transaksi')
                                String jenis = item['jenis'] ?? 'Transaksi';
                                double nominal =
                                    (item['jumlah'] as num?)?.toDouble() ?? 0;
                                String tanggal = item['tgl_transaksi'] ?? '-';
                                String ket = item['keterangan'] ?? '-';

                                // Logika Warna: Setoran/Bagi Hasil = Hijau (Masuk)
                                bool isMasuk = [
                                  'Setoran',
                                  'Setor Tunai',
                                  'Bagi Hasil',
                                  'Setoran Awal'
                                ].any((e) => jenis.contains(e));

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 5),
                                  leading: CircleAvatar(
                                    backgroundColor: isMasuk
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                                    child: Icon(
                                      isMasuk
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward,
                                      color:
                                          isMasuk ? Colors.green : Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(jenis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(tanggal,
                                          style: const TextStyle(fontSize: 12)),
                                      if (ket != '-' && ket.isNotEmpty)
                                        Text(ket,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.grey)),
                                    ],
                                  ),
                                  trailing: Text(
                                    "${isMasuk ? '+' : '-'} ${_formatter.format(nominal)}",
                                    style: TextStyle(
                                      color: isMasuk
                                          ? Colors.green[700]
                                          : Colors.red[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    // Tombol Tutup
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))),
                          child: const Text("TUTUP",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      debugPrint("Gagal membuka riwayat: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal memuat riwayat: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Detail Nasabah'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          EditAnggotaPage(nasabah: _currentNasabah)));
              if (result == true) _refreshData();
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. PROFIL HEADER
              _buildProfileHeader(),
              const SizedBox(height: 20),

              // 2. KARTU SALDO WADIAH
              const Text("KEUANGAN UTAMA",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              _buildWadiahCard(),
              const SizedBox(height: 25),

              // 3. MENU FASILITAS
              const Text("FASILITAS & PEMBIAYAAN",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.3,
                children: [
                  _buildMenuButton(
                    title: "Jual Beli\n(Murabahah)",
                    icon: Icons.shopping_cart,
                    color: Colors.blue,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => DetailJualBeliAnggotaPage(
                                nasabahId: _currentNasabah['id']))),
                  ),
                  _buildMenuButton(
                    title: "Bagi Hasil\n(Mudharabah)",
                    icon: Icons.handshake,
                    color: Colors.purple,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => DetailBagiHasilAnggotaPage(
                                nasabahId: _currentNasabah['id']))),
                  ),
                  _buildMenuButton(
                    title: "Pinjaman Lunak\n(Qardhul Hasan)",
                    icon: Icons.volunteer_activism,
                    color: Colors.orange,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                DetailPinjamanLunakAnggotaPage(
                                    nasabahId: _currentNasabah['id']))),
                  ),
                  _buildMenuButton(
                    title: "Usaha Bersama\n(Investasi)",
                    icon: Icons.storefront,
                    color: Colors.teal,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => DetailUsahaBersamaAnggotaPage(
                                nasabahId: _currentNasabah['id'],
                                namaNasabah: _currentNasabah['nama']))),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 4. TOMBOL HAPUS
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _konfirmasiHapus,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text("Hapus Anggota Ini",
                      style: TextStyle(color: Colors.red)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildMenuButton(
      {required String title,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 10),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF2E7D32),
            child: Text(_currentNasabah['nama'][0].toUpperCase(),
                style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_currentNasabah['nama'],
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text("NIK: ${_currentNasabah['nik'] ?? '-'}",
                  style: const TextStyle(color: Colors.grey)),
              Text("Telp: ${_currentNasabah['telepon'] ?? '-'}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildWadiahCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF43A047)]),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Saldo Simpanan", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 5),
          Text(_formatter.format(_saldoWadiah),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),

          // TOMBOL BARU: RIWAYAT MUTASI
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showRiwayatMutasi,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              icon: const Icon(Icons.history),
              label: const Text("Lihat Riwayat Mutasi",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  void _konfirmasiHapus() async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Hapus Anggota"),
            content: const Text(
                "Apakah Anda yakin? Data yang dihapus tidak dapat dikembalikan."),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Batal")),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Hapus",
                      style: TextStyle(color: Colors.white))),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await _dbHelper.deleteAnggota(_currentNasabah['id']);
      if (mounted) {
        Navigator.pop(context, true); // Kembali ke list & refresh
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Anggota berhasil dihapus")));
      }
    }
  }
}
