import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// UBAH: Gunakan ApiService
import '../../../services/api_service.dart';
import 'pj_pelaksana_page.dart';
import 'permodalan_page.dart';
import 'pemasukan_usaha_page.dart';
import 'laporan_usaha_page.dart';

class MenuUsahaBersamaPage extends StatefulWidget {
  final Map<String, dynamic> usaha;

  const MenuUsahaBersamaPage({super.key, required this.usaha});

  @override
  State<MenuUsahaBersamaPage> createState() => _MenuUsahaBersamaPageState();
}

class _MenuUsahaBersamaPageState extends State<MenuUsahaBersamaPage> {
  // UBAH: Inisialisasi ApiService
  final ApiService _apiService = ApiService();
  final NumberFormat _formatter =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  double _totalModalTerkumpul = 0;

  @override
  void initState() {
    super.initState();
    _hitungModalTerkumpul();
  }

  // Fungsi menghitung total modal real dari API
  Future<void> _hitungModalTerkumpul() async {
    int usahaId = int.tryParse(widget.usaha['id'].toString()) ?? 0;
    double total = await _apiService.getModalUsahaTerkumpul(usahaId);

    if (mounted) {
      setState(() {
        _totalModalTerkumpul = total;
      });
    }
  }

  // --- FUNGSI HAPUS USAHA (ONLINE) ---
  Future<void> _hapusUsaha() async {
    // 1. Tampilkan Dialog Konfirmasi
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Hapus Usaha"),
            content: const Text(
                "Yakin ingin menghapus usaha ini beserta seluruh datanya? Data yang dihapus tidak dapat dikembalikan."),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Batal")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child:
                    const Text("Hapus", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ) ??
        false;

    // 2. Eksekusi Hapus
    if (confirm) {
      int id = int.tryParse(widget.usaha['id'].toString()) ?? 0;

      // Panggil API Hapus
      bool success = await _apiService.deleteUsahaBersama(id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Data Usaha berhasil dihapus dari Server")),
          );
          Navigator.pop(context); // Kembali ke halaman list usaha
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Gagal menghapus data"),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usaha = widget.usaha;
    // Parsing Modal Awal
    double modalAwal = double.tryParse(usaha['modal_awal'].toString()) ?? 0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(usaha['nama_usaha'] ?? 'Detail Usaha'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          // --- TOMBOL HAPUS DI APPBAR ---
          IconButton(
            onPressed: _hapusUsaha,
            icon: const Icon(Icons.delete),
            tooltip: "Hapus Usaha",
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header Ringkasan Usaha
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kolom Kiri: Rencana
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Rencana Modal",
                              style: TextStyle(
                                  color: Colors.green[100], fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatter.format(modalAwal),
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white30),
                            ),
                          ],
                        ),
                      ),
                      // Kolom Kanan: Terkumpul (Highlight)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "Terkumpul (Real)",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatter.format(_totalModalTerkumpul),
                              style: const TextStyle(
                                color: Colors.yellowAccent,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Baris Info Tambahan
                  Row(
                    children: [
                      Icon(Icons.category, color: Colors.green[100], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        usaha['jenis_usaha'] ?? '-',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const Spacer(),
                      Icon(Icons.calendar_today,
                          color: Colors.green[100], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        usaha['tgl_mulai'] ?? '-',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (usaha['deskripsi'] != null &&
                      usaha['deskripsi'].toString().isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        usaha['deskripsi'],
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Menu Grid (Tombol Navigasi)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Menu Manajemen",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  // Menu 1: PJ & Pelaksana
                  _buildMenuCard(
                    context,
                    title: "PJ & Pelaksana",
                    subtitle: "Kelola pengurus & anggota",
                    icon: Icons.groups,
                    color: Colors.blue,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PjPelaksanaPage(usaha: widget.usaha),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Menu 2: Permodalan (Investor)
                  _buildMenuCard(
                    context,
                    title: "Permodalan",
                    subtitle: "Setoran modal investor/anggota",
                    icon: Icons.account_balance_wallet,
                    color: Colors.orange,
                    onTap: () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  PermodalanPage(usaha: widget.usaha)));
                      _hitungModalTerkumpul(); // Refresh header saat kembali
                    },
                  ),

                  const SizedBox(height: 12),

                  // Menu 3: Pemasukan Usaha
                  _buildMenuCard(
                    context,
                    title: "Pemasukan Usaha",
                    subtitle: "Catat omset & pendapatan harian",
                    icon: Icons.monetization_on_rounded,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  PemasukanUsahaPage(usaha: widget.usaha)));
                    },
                  ),

                  const SizedBox(height: 12),

                  // Menu 4: Laporan Usaha
                  _buildMenuCard(
                    context,
                    title: "Laporan Usaha",
                    subtitle: "Rekap keuangan & bagi hasil",
                    icon: Icons.insert_chart,
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  LaporanUsahaPage(usaha: widget.usaha)));
                    },
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
