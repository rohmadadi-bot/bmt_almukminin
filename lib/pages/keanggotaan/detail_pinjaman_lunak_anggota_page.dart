import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/db_helper.dart';

class DetailPinjamanLunakAnggotaPage extends StatefulWidget {
  final int nasabahId;
  const DetailPinjamanLunakAnggotaPage({super.key, required this.nasabahId});

  @override
  State<DetailPinjamanLunakAnggotaPage> createState() =>
      _DetailPinjamanLunakAnggotaPageState();
}

class _DetailPinjamanLunakAnggotaPageState
    extends State<DetailPinjamanLunakAnggotaPage> {
  final DbHelper _dbHelper = DbHelper();
  final NumberFormat _formatter =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  List<Map<String, dynamic>> _dataPinjaman = [];
  bool _isLoading = true;

  // Variabel Header Statistik
  double _totalPinjamanDisalurkan = 0; // Total Plafond
  double _totalCicilanMasuk = 0; // Sudah Bayar
  double _totalSisaTagihan = 0; // Sisa Hutang

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _totalPinjamanDisalurkan = 0;
      _totalCicilanMasuk = 0;
      _totalSisaTagihan = 0;
    });

    try {
      final db = await _dbHelper.database;

      // 1. Ambil Data Pinjaman berdasarkan Nasabah
      final List<Map<String, dynamic>> pinjamanList = await db.query(
        'pinjaman_lunak',
        where: 'nasabah_id = ?',
        whereArgs: [widget.nasabahId],
        orderBy: 'id DESC',
      );

      List<Map<String, dynamic>> processedList = [];
      double tempTotalPinjaman = 0;
      double tempTotalCicilan = 0;

      // 2. Loop untuk hitung sisa per akad dan total statistik
      for (var p in pinjamanList) {
        // Ambil total yang sudah dibayar di tabel cicilan
        var resBayar = await db.rawQuery(
            "SELECT SUM(jumlah_bayar) as total FROM pinjaman_lunak_cicilan WHERE pinjaman_id = ?",
            [p['id']]);

        double nominal = (p['nominal'] as num?)?.toDouble() ?? 0.0;
        double sudahBayar =
            (resBayar.first['total'] as num?)?.toDouble() ?? 0.0;
        double sisa = nominal - sudahBayar;

        // Update Statistik Header (Hanya yg Disetujui/Lunas)
        if (p['status'] == 'Disetujui' || p['status'] == 'Lunas') {
          tempTotalPinjaman += nominal;
          tempTotalCicilan += sudahBayar;
        }

        var newItem = Map<String, dynamic>.from(p);
        newItem['sisa'] = sisa;
        newItem['sudah_bayar'] = sudahBayar;
        processedList.add(newItem);
      }

      if (mounted) {
        setState(() {
          _dataPinjaman = processedList;
          _totalPinjamanDisalurkan = tempTotalPinjaman;
          _totalCicilanMasuk = tempTotalCicilan;
          // Hitung Sisa Tagihan Global
          _totalSisaTagihan = tempTotalPinjaman - tempTotalCicilan;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error load data pinjaman: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- SHOW RIWAYAT CICILAN (BOTTOM SHEET) ---
  void _showRiwayatCicilan(Map<String, dynamic> pinjaman) async {
    try {
      final db = await _dbHelper.database;
      final riwayat = await db.query(
        'pinjaman_lunak_cicilan',
        where: 'pinjaman_id = ?',
        whereArgs: [pinjaman['id']],
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

                    // Header Bottom Sheet
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Riwayat Cicilan",
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(pinjaman['deskripsi'] ?? 'Pinjaman',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 4),
                          Text(
                              "Total Pinjaman: ${_formatter.format(pinjaman['nominal'])}",
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.orange)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // List Riwayat
                    Expanded(
                      child: riwayat.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long,
                                      size: 60, color: Colors.grey[300]),
                                  const SizedBox(height: 10),
                                  const Text("Belum ada data cicilan",
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              itemCount: riwayat.length,
                              separatorBuilder: (ctx, i) =>
                                  const Divider(height: 1),
                              itemBuilder: (ctx, i) {
                                final item = riwayat[i];
                                double bayar = (item['jumlah_bayar'] as num?)
                                        ?.toDouble() ??
                                    0.0;

                                String tgl = item['tgl_bayar'] != null
                                    ? item['tgl_bayar'].toString()
                                    : '-';
                                String ket = item['keterangan'] != null
                                    ? item['keterangan'].toString()
                                    : '-';

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 5),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.orange[50],
                                    child: const Icon(Icons.download_done,
                                        color: Colors.orange, size: 20),
                                  ),
                                  title: Text(_formatter.format(bayar),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(tgl),
                                      if (ket != '-' && ket.isNotEmpty)
                                        Text(ket,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.grey)),
                                    ],
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
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange)),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal memuat riwayat cicilan")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Pinjaman Lunak"),
        backgroundColor: Colors.orange,
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
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Judul & Total Pinjaman
                      const Text("Total Pinjaman (Plafond)",
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 5),
                      Text(
                        _formatter.format(_totalPinjamanDisalurkan),
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 20),

                      // Row Statistik: Total Masuk & Sisa Tagihan
                      Row(
                        children: [
                          // Kiri: Sudah Dibayar
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Sudah Dibayar",
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatter.format(_totalCicilanMasuk),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Kanan: Sisa Tagihan
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Sisa Tagihan",
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatter.format(_totalSisaTagihan),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
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
                  padding: EdgeInsets.only(left: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Riwayat Akad",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 5),

                // --- 2. LIST PINJAMAN ---
                Expanded(
                  child: _dataPinjaman.isEmpty
                      ? const Center(
                          child: Text("Tidak ada riwayat pinjaman",
                              style: TextStyle(color: Colors.grey)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _dataPinjaman.length,
                          separatorBuilder: (ctx, i) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = _dataPinjaman[index];
                            double nominal =
                                (item['nominal'] as num?)?.toDouble() ?? 0.0;
                            double sisa = item['sisa'];
                            String status = item['status'] ?? 'Pengajuan';

                            // Warna status
                            Color statusColor = Colors.grey;
                            if (status == 'Disetujui')
                              statusColor = Colors.orange;
                            if (status == 'Lunas') statusColor = Colors.green;
                            if (status == 'Ditolak') statusColor = Colors.red;

                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                      color: statusColor.withOpacity(0.5))),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _showRiwayatCicilan(item),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                                item['deskripsi'] ?? 'Pinjaman',
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16)),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                                color: statusColor,
                                                borderRadius:
                                                    BorderRadius.circular(5)),
                                            child: Text(status,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(item['tgl_pengajuan'] ?? '-',
                                          style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12)),
                                      const Divider(),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text("Total Pinjaman",
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey)),
                                              Text(_formatter.format(nominal),
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500)),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              const Text("Sisa Tagihan",
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey)),
                                              Text(_formatter.format(sisa),
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                      color: sisa <= 0
                                                          ? Colors.green
                                                          : Colors.red)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
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
