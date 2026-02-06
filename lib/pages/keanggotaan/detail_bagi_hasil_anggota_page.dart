import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/db_helper.dart';

class DetailBagiHasilAnggotaPage extends StatefulWidget {
  final int nasabahId;
  const DetailBagiHasilAnggotaPage({super.key, required this.nasabahId});

  @override
  State<DetailBagiHasilAnggotaPage> createState() =>
      _DetailBagiHasilAnggotaPageState();
}

class _DetailBagiHasilAnggotaPageState
    extends State<DetailBagiHasilAnggotaPage> {
  final DbHelper _dbHelper = DbHelper();
  final NumberFormat _formatter =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  List<Map<String, dynamic>> _dataAkad = [];
  bool _isLoading = true;

  // Variabel Header Statistik
  double _totalModalDisalurkan = 0; // "Hutang" Bagi Hasil
  double _totalKeuntunganUsaha = 0; // Total Omzet Nasabah
  double _totalBagiHasilBMT = 0; // Masuk ke BMT

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await _dbHelper.database;

    // 1. Ambil Akad
    final akadList = await db.query(
      'mudharabah_akad',
      where: 'nasabah_id = ?',
      whereArgs: [widget.nasabahId],
      orderBy: 'id DESC',
    );

    double tempModal = 0;
    double tempKeuntungan = 0;
    double tempBagiHasil = 0;

    // 2. Hitung Total & Ambil Data Transaksi
    for (var akad in akadList) {
      if (akad['status'] == 'Disetujui' || akad['status'] == 'Aktif') {
        tempModal += (akad['nominal_modal'] as num?)?.toDouble() ?? 0;
      }

      final transaksiList = await db.query(
        'mudharabah_transaksi',
        where: 'akad_id = ?',
        whereArgs: [akad['id']],
      );

      for (var tr in transaksiList) {
        tempKeuntungan += (tr['total_keuntungan'] as num?)?.toDouble() ?? 0;
        tempBagiHasil += (tr['bagian_bmt'] as num?)?.toDouble() ?? 0;
      }
    }

    if (mounted) {
      setState(() {
        _dataAkad = akadList;
        _totalModalDisalurkan = tempModal;
        _totalKeuntunganUsaha = tempKeuntungan;
        _totalBagiHasilBMT = tempBagiHasil;
        _isLoading = false;
      });
    }
  }

  // --- FUNGSI MENAMPILKAN RIWAYAT TRANSAKSI (POP-UP BAWAH) ---
  void _showRiwayatTransaksi(Map<String, dynamic> akad) async {
    final db = await _dbHelper.database;

    // Pastikan nama tabel benar: 'mudharabah_transaksi'
    final riwayat = await db.query(
      'mudharabah_transaksi',
      where: 'akad_id = ?',
      whereArgs: [akad['id']],
      orderBy: 'id DESC',
    );

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 15),
              Text("Riwayat: ${akad['nama_usaha']}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              const Divider(),
              Expanded(
                child: riwayat.isEmpty
                    ? const Center(
                        child: Text("Belum ada transaksi bagi hasil",
                            style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        itemCount: riwayat.length,
                        separatorBuilder: (ctx, i) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = riwayat[index];

                          // --- PERBAIKAN DI SINI (SOLUSI ERROR) ---
                          // 1. Ambil sebagai Object/var dulu
                          var rawTgl = item['tgl_transaksi'];

                          // 2. Konversi paksa ke String agar tidak error type mismatch
                          String tgl = rawTgl != null ? rawTgl.toString() : '-';

                          // Ambil data angka dengan aman
                          double keuntunganTotal =
                              (item['total_keuntungan'] as num?)?.toDouble() ??
                                  0;
                          double bagianBmt =
                              (item['bagian_bmt'] as num?)?.toDouble() ?? 0;
                          double bagianNasabah =
                              (item['bagian_nasabah'] as num?)?.toDouble() ?? 0;
                          // ----------------------------------------

                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.payments,
                                  color: Colors.purple, size: 20),
                            ),
                            title: Text(
                              "BMT: ${_formatter.format(bagianBmt)}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    "Total Omzet: ${_formatter.format(keuntunganTotal)}"),
                                Text(
                                    "Nasabah: ${_formatter.format(bagianNasabah)}",
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                            trailing: Text(
                              tgl,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Detail Bagi Hasil"),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // --- 1. HEADER SUMMARY ---
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
                  decoration: BoxDecoration(
                    color: Colors.purple[700],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text("Total Modal Disalurkan",
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 5),
                      Text(
                        _formatter.format(_totalModalDisalurkan),
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                children: [
                                  const Text("Total Keuntungan",
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 11)),
                                  const SizedBox(height: 5),
                                  Text(
                                    _formatter.format(_totalKeuntunganUsaha),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                children: [
                                  const Text("Masuk BMT",
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 11)),
                                  const SizedBox(height: 5),
                                  Text(
                                    _formatter.format(_totalBagiHasilBMT),
                                    style: const TextStyle(
                                        color: Colors.greenAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 15),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Daftar Akad Usaha",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey)),
                  ),
                ),
                const SizedBox(height: 5),

                // --- 2. LIST AKAD ---
                Expanded(
                  child: _dataAkad.isEmpty
                      ? const Center(
                          child: Text("Tidak ada program Bagi Hasil"))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _dataAkad.length,
                          separatorBuilder: (ctx, i) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = _dataAkad[index];

                            // Logika Warna Status
                            Color statusColor = item['status'] == 'Disetujui'
                                ? Colors.green
                                : Colors.orange;

                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.purple[50],
                                  child: Icon(Icons.store,
                                      color: Colors.purple[700]),
                                ),
                                title: Text(item['nama_usaha'] ?? 'Usaha',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                        "Modal: ${_formatter.format(item['nominal_modal'] ?? 0)}"),
                                    Text(
                                        "Nisbah: ${(item['nisbah_nasabah'] ?? 0).toInt()} : ${(item['nisbah_bmt'] ?? 0).toInt()} (N:B)"),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(item['status'] ?? '-',
                                        style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12)),
                                    const Icon(Icons.keyboard_arrow_right,
                                        size: 16, color: Colors.grey)
                                  ],
                                ),
                                onTap: () => _showRiwayatTransaksi(item),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
