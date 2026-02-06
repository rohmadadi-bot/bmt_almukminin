import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/db_helper.dart';

class DetailAkadPinjamanLunakPage extends StatefulWidget {
  final Map<String, dynamic> dataPinjaman;

  const DetailAkadPinjamanLunakPage({super.key, required this.dataPinjaman});

  @override
  State<DetailAkadPinjamanLunakPage> createState() =>
      _DetailAkadPinjamanLunakPageState();
}

class _DetailAkadPinjamanLunakPageState
    extends State<DetailAkadPinjamanLunakPage> {
  final DbHelper _dbHelper = DbHelper();
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.dataPinjaman['status'];
  }

  // --- FUNGSI HAPUS AKAD (BARU) ---
  Future<void> _hapusAkad() async {
    // 1. Tampilkan Dialog Konfirmasi
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Hapus Akad"),
            content: const Text(
                "Yakin ingin menghapus data akad ini secara permanen? Data yang dihapus tidak dapat dikembalikan."),
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

    // 2. Eksekusi Hapus jika User klik Ya
    if (confirm) {
      final db = await _dbHelper.database;
      // Pastikan nama tabel sesuai dengan database Anda (biasanya 'pinjaman_lunak')
      await db.delete('pinjaman_lunak',
          where: 'id = ?', whereArgs: [widget.dataPinjaman['id']]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data akad berhasil dihapus")),
        );
        Navigator.pop(context); // Kembali ke halaman list
      }
    }
  }

  // --- FUNGSI UPDATE STATUS ---
  Future<void> _updateStatus(String newStatus) async {
    await _dbHelper.updateStatusPinjaman(widget.dataPinjaman['id'], newStatus);
    setState(() {
      _currentStatus = newStatus;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Status berhasil diubah menjadi: $newStatus"),
          backgroundColor: _getColorByStatus(newStatus),
        ),
      );
    }
  }

  // --- FUNGSI KIRIM WA ---
  Future<void> _launchWhatsApp({String? phone, required String message}) async {
    String urlString;

    if (phone != null && phone.isNotEmpty) {
      String formattedPhone = phone;
      if (formattedPhone.startsWith('0')) {
        formattedPhone = "62${formattedPhone.substring(1)}";
      }
      urlString =
          "https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}";
    } else {
      urlString = "https://wa.me/?text=${Uri.encodeComponent(message)}";
    }

    final Uri url = Uri.parse(urlString);

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("Gagal membuka WhatsApp. Cek koneksi atau aplikasi.")),
        );
      }
    }
  }

  Color _getColorByStatus(String status) {
    switch (status) {
      case 'Disetujui':
        return Colors.green;
      case 'Tidak Disetujui':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getIconByStatus(String status) {
    switch (status) {
      case 'Disetujui':
        return Icons.check_circle;
      case 'Tidak Disetujui':
        return Icons.cancel;
      default:
        return Icons.access_time_filled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Akad Qardhul Hasan"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          // --- TOMBOL HAPUS DI APP BAR ---
          IconButton(
            onPressed: _hapusAkad,
            icon: const Icon(Icons.delete),
            tooltip: "Hapus Data Akad",
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // --- KARTU STATUS ---
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(_getIconByStatus(_currentStatus),
                        size: 60, color: _getColorByStatus(_currentStatus)),
                    const SizedBox(height: 10),
                    Text(
                      _currentStatus.toUpperCase(),
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _getColorByStatus(_currentStatus)),
                    ),
                    const SizedBox(height: 5),
                    const Text("Status Saat Ini",
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- INFO AKAD ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildRow("Nama Nasabah",
                        widget.dataPinjaman['nama_nasabah'] ?? '-'),
                    const Divider(),
                    _buildRow(
                        "Telepon/WA", widget.dataPinjaman['telepon'] ?? '-'),
                    const Divider(),
                    _buildRow("Tanggal Pengajuan",
                        widget.dataPinjaman['tgl_pengajuan']),
                    const Divider(),
                    _buildRow(
                        "Nominal",
                        currencyFormatter
                            .format(widget.dataPinjaman['nominal'])),
                    const Divider(),
                    _buildRow("Keperluan", widget.dataPinjaman['deskripsi']),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // --- BAGIAN 1: TOMBOL AKSI WHATSAPP ---
            const Align(
                alignment: Alignment.centerLeft,
                child: Text("Aksi Komunikasi:",
                    style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon:
                        const Icon(Icons.share, color: Colors.white, size: 18),
                    label: const Text("Tinjau Pimpinan",
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                    onPressed: () {
                      String msg = "*PENGAJUAN PINJAMAN LUNAK*\n\n"
                          "Mohon tinjauannya Pak/Bu untuk pengajuan berikut:\n"
                          "Nama: ${widget.dataPinjaman['nama_nasabah']}\n"
                          "Nominal: ${currencyFormatter.format(widget.dataPinjaman['nominal'])}\n"
                          "Keperluan: ${widget.dataPinjaman['deskripsi']}\n\n"
                          "Terima Kasih.";
                      _launchWhatsApp(phone: null, message: msg);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    label: const Text("Info ke Nasabah",
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                    onPressed: () {
                      String phone = widget.dataPinjaman['telepon'] ?? '';
                      if (phone.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("No HP Nasabah tidak tersedia")),
                        );
                        return;
                      }

                      String statusMsg = "";
                      if (_currentStatus == 'Disetujui') {
                        statusMsg =
                            "Alhamdulillah, pengajuan Pinjaman Lunak Anda telah *DISETUJUI*. Silakan datang ke kantor BMT untuk pencairan.";
                      } else if (_currentStatus == 'Tidak Disetujui') {
                        statusMsg =
                            "Mohon maaf, pengajuan Pinjaman Lunak Anda *BELUM DISETUJUI* saat ini.";
                      } else {
                        statusMsg =
                            "Pengajuan Pinjaman Lunak Anda saat ini sedang dalam proses *PENGAJUAN*.";
                      }

                      String msg =
                          "Assalamu'alaikum ${widget.dataPinjaman['nama_nasabah']},\n\n$statusMsg\n\nTerima Kasih.\nBMT Al-Mukminin";

                      _launchWhatsApp(phone: phone, message: msg);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- BAGIAN 2: TOMBOL PERUBAHAN STATUS ---
            const Align(
                alignment: Alignment.centerLeft,
                child: Text("Update Status:",
                    style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                    backgroundColor: _currentStatus == 'Pengajuan'
                        ? Colors.orange[50]
                        : null),
                onPressed: () => _updateStatus('Pengajuan'),
                child: const Text("Kembalikan ke Pengajuan",
                    style: TextStyle(color: Colors.orange)),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        padding: const EdgeInsets.symmetric(vertical: 15)),
                    onPressed: () => _updateStatus('Tidak Disetujui'),
                    child: const Text("TIDAK DISETUJUI",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(vertical: 15)),
                    onPressed: () => _updateStatus('Disetujui'),
                    child: const Text("DISETUJUI",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Expanded(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16))),
        ],
      ),
    );
  }
}
