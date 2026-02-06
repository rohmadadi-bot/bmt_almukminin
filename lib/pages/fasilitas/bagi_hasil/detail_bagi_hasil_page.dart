import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/db_helper.dart';

class DetailBagiHasilPage extends StatelessWidget {
  final Map<String, dynamic> transaksiData;

  const DetailBagiHasilPage({super.key, required this.transaksiData});

  // --- LOGIKA HAPUS TRANSAKSI ---
  Future<void> _hapusTransaksi(BuildContext context) async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Hapus Transaksi"),
            content: const Text(
                "Yakin ingin menghapus data bagi hasil ini? Data tidak dapat dikembalikan."),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Batal")),
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
      final dbHelper = DbHelper();
      final db = await dbHelper.database;

      // Hapus dari tabel mudharabah_transaksi
      await db.delete('mudharabah_transaksi',
          where: 'id = ?', whereArgs: [transaksiData['id']]);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Transaksi berhasil dihapus")));
        // Kembali ke halaman sebelumnya dengan sinyal refresh (true)
        Navigator.pop(context, true);
      }
    }
  }

  // --- LOGIKA KIRIM WA ---
  Future<void> _kirimWA(BuildContext context, NumberFormat formatter) async {
    String rawPhone = transaksiData['telepon']?.toString() ?? "";
    String namaNasabah = transaksiData['nama_nasabah'] ?? "Nasabah";

    // Cek database jika nomor telepon belum ada di transaksiData
    if (rawPhone.isEmpty && transaksiData['nasabah_id'] != null) {
      final db = await DbHelper().database;
      final res = await db.query('anggota',
          columns: ['telepon', 'nama'],
          where: 'id = ?',
          whereArgs: [transaksiData['nasabah_id']]);
      if (res.isNotEmpty) {
        rawPhone = res.first['telepon']?.toString() ?? "";
        namaNasabah = res.first['nama']?.toString() ?? namaNasabah;
      }
    }

    if (rawPhone.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Nomor WA tidak ditemukan.")));
      }
      return;
    }

    // Format Nomor
    String phone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.startsWith('0')) phone = '62${phone.substring(1)}';
    if (phone.startsWith('8')) phone = '62$phone';

    // Template Pesan
    String pesan = "📊 *RINCIAN BAGI HASIL USAHA*\n"
        "🏛 *BMT AL MUKMININ*\n"
        "--------------------------------\n"
        "Yth. $namaNasabah\n"
        "Berikut rincian bagi hasil periode ini:\n\n"
        "📅 Tanggal : ${transaksiData['tgl_transaksi']}\n"
        "💰 Total Profit : ${formatter.format(transaksiData['total_keuntungan'])}\n"
        "--------------------------------\n"
        "PEMBAGIAN:\n"
        "👤 Pengelola : ${formatter.format(transaksiData['bagian_nasabah'])}\n"
        "🏦 BMT : ${formatter.format(transaksiData['bagian_bmt'])}\n"
        "--------------------------------\n"
        "_Terima kasih atas kerjasamanya._";

    final String url =
        "https://wa.me/$phone?text=${Uri.encodeComponent(pesan)}";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Gagal membuka WhatsApp")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormatter =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Rincian Bagi Hasil"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          // --- TOMBOL HAPUS DI APPBAR ---
          IconButton(
            onPressed: () => _hapusTransaksi(context),
            icon: const Icon(Icons.delete),
            tooltip: "Hapus Transaksi",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // KARTU UTAMA
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 60, color: Colors.green),
                    const SizedBox(height: 10),
                    const Text("Transaksi Tercatat",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(transaksiData['tgl_transaksi'] ?? '-',
                        style: const TextStyle(color: Colors.grey)),
                    const Divider(height: 30),
                    const Text("Total Keuntungan Usaha",
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 5),
                    Text(
                      currencyFormatter
                          .format(transaksiData['total_keuntungan']),
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // KARTU RINCIAN PEMBAGIAN
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(15))),
                    child: const Text("Distribusi Bagi Hasil",
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildRow(
                            "Bagian Pengelola (Nasabah)",
                            currencyFormatter
                                .format(transaksiData['bagian_nasabah']),
                            Colors.blue),
                        const Divider(height: 30),
                        _buildRow(
                            "Bagian BMT (Pemodal)",
                            currencyFormatter
                                .format(transaksiData['bagian_bmt']),
                            Colors.green),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- TOMBOL AKSI BAWAH (Hanya Kirim WA) ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _kirimWA(context, currencyFormatter),
                icon: const Icon(Icons.share, color: Colors.white),
                label: const Text("KIRIM BUKTI WA",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366), // Warna WA
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context), // Balik tanpa refresh
                child:
                    const Text("Kembali", style: TextStyle(color: Colors.grey)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
