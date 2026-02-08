import 'package:flutter/material.dart';
// UBAH: Gunakan ApiService
import '../../../services/api_service.dart';

import 'akad_bagi_hasil_page.dart';
import 'transaksi_bagi_hasil_page.dart';

class MenuBagiHasilPage extends StatefulWidget {
  final Map<String, dynamic> akadData;

  const MenuBagiHasilPage({super.key, required this.akadData});

  @override
  State<MenuBagiHasilPage> createState() => _MenuBagiHasilPageState();
}

class _MenuBagiHasilPageState extends State<MenuBagiHasilPage> {
  // UBAH: Inisialisasi ApiService
  final ApiService _apiService = ApiService();
  late Map<String, dynamic> _currentAkadData;

  @override
  void initState() {
    super.initState();
    _currentAkadData = widget.akadData;
  }

  // --- HAPUS AKAD (ONLINE) ---
  Future<void> _hapusAkad() async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Hapus Akad"),
            content: const Text(
                "Yakin ingin menghapus akad ini dari SERVER? Data yang dihapus tidak dapat dikembalikan."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child:
                    const Text("Hapus", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      int id = int.tryParse(_currentAkadData['id'].toString()) ?? 0;

      // Panggil API (Kita perlu menambahkan fungsi ini di ApiService nanti)
      bool success = await _apiService.deleteAkadBagiHasil(id);

      if (mounted) {
        if (success) {
          Navigator.pop(context); // Kembali ke list
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Akad berhasil dihapus dari Server")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Gagal menghapus akad"),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // --- UPDATE STATUS (ONLINE) ---
  Future<void> _updateStatus(String newStatus) async {
    int id = int.tryParse(_currentAkadData['id'].toString()) ?? 0;

    // Panggil API Update Status
    bool success = await _apiService.updateStatusAkadBagiHasil(id, newStatus);

    if (mounted) {
      if (success) {
        setState(() {
          // Update status di memory lokal agar UI berubah langsung
          _currentAkadData['status'] = newStatus;
        });

        // Tentukan warna snackbar
        Color snackColor = Colors.orange;
        if (newStatus == 'Disetujui') snackColor = Colors.green;
        if (newStatus == 'Ditolak') snackColor = Colors.red;
        if (newStatus == 'Selesai') snackColor = Colors.blueGrey;

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Status diubah menjadi: $newStatus"),
          backgroundColor: snackColor,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Gagal update status"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String namaUsaha = _currentAkadData['nama_usaha'] ?? 'Usaha Mudharabah';
    String deskripsi = _currentAkadData['deskripsi_usaha'] ?? '-';
    String namaNasabah = _currentAkadData['nama_nasabah'] ?? 'Nasabah';
    String tglAkad = _currentAkadData['tgl_akad'] ?? '-';
    String status = _currentAkadData['status'] ?? 'Pengajuan';

    double modal =
        double.tryParse(_currentAkadData['nominal_modal'].toString()) ?? 0;
    double nNasabah =
        double.tryParse(_currentAkadData['nisbah_nasabah'].toString()) ?? 0;
    double nBmt =
        double.tryParse(_currentAkadData['nisbah_bmt'].toString()) ?? 0;

    // Logic Warna & Ikon Status
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'Disetujui':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Ditolak':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'Selesai':
        statusColor = Colors.blueGrey;
        statusIcon = Icons.flag;
        break;
      default: // Pengajuan
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(namaNasabah),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // TOMBOL HAPUS (BARU)
          IconButton(
            onPressed: _hapusAkad,
            icon: const Icon(Icons.delete),
            tooltip: "Hapus Akad",
          )
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // HEADER INFORMASI USAHA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
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
                  // --- STATUS BADGE (Top Right) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            Icon(statusIcon, size: 16, color: statusColor),
                            const SizedBox(width: 5),
                            Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.store, color: Colors.white54),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // NAMA USAHA
                  const Text(
                    "Nama Usaha",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    namaUsaha,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    deskripsi,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 15),

                  // INFO MODAL & NISBAH
                  if (modal > 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Modal BMT",
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 10)),
                              Text("Rp ${modal.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Container(
                              height: 30, width: 1, color: Colors.white30),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text("Nisbah (N:B)",
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 10)),
                              Text("${nNasabah.toInt()} : ${nBmt.toInt()}",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month,
                          color: Colors.white54, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        "Tanggal Akad: $tglAkad",
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24),
                  const Text("Update Status:",
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(height: 8),

                  // --- TOMBOL PERSETUJUAN (GRID 2 Baris) ---
                  Column(
                    children: [
                      // Baris 1: Pengajuan & Disetujui
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatusActionBtn(
                              label: "Pengajuan",
                              color: Colors.orange,
                              isActive: status == 'Pengajuan',
                              onTap: () => _updateStatus('Pengajuan'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatusActionBtn(
                              label: "Disetujui",
                              color: const Color(0xFF4CAF50),
                              isActive: status == 'Disetujui',
                              onTap: () => _updateStatus('Disetujui'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Baris 2: Ditolak & Selesai
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatusActionBtn(
                              label: "Ditolak",
                              color: Colors.redAccent,
                              isActive: status == 'Ditolak',
                              onTap: () => _updateStatus('Ditolak'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatusActionBtn(
                              label: "Selesai",
                              color: Colors.blueGrey,
                              isActive: status == 'Selesai',
                              onTap: () => _updateStatus('Selesai'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            // MENU UTAMA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // TOMBOL 1: TRANSAKSI BAGI HASIL
                  _buildMenuButton(
                    title: "Transaksi Bagi Hasil",
                    subtitle: "Input setoran modal & pembagian keuntungan",
                    icon: Icons.payments_outlined,
                    color: Colors.orange,
                    // Hanya bisa transaksi jika DISETUJUI
                    isLocked: status != 'Disetujui',
                    onTap: () {
                      if (status != 'Disetujui') {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                "Akad harus berstatus DISETUJUI untuk melakukan transaksi.")));
                        return;
                      }
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => TransaksiBagiHasilPage(
                                  akadData: _currentAkadData)));
                    },
                  ),

                  const SizedBox(height: 16),

                  // TOMBOL 2: DETAIL AKAD
                  _buildMenuButton(
                    title: "Detail Akad",
                    subtitle: "Lihat perjanjian, modal, & nisbah",
                    icon: Icons.handshake_outlined,
                    color: Colors.blue,
                    isLocked: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AkadBagiHasilPage(akadData: _currentAkadData),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusActionBtn(
      {required String label,
      required Color color,
      required bool isActive,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isActive ? Colors.white : Colors.white30, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isLocked,
  }) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isLocked ? Colors.grey[200] : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(isLocked ? Icons.lock : icon,
                    color: isLocked ? Colors.grey : color, size: 30),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isLocked ? Colors.grey : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[300], size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
