import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class DetailBagiHasilAnggotaPage extends StatefulWidget {
  final int nasabahId;
  const DetailBagiHasilAnggotaPage({super.key, required this.nasabahId});

  @override
  State<DetailBagiHasilAnggotaPage> createState() =>
      _DetailBagiHasilAnggotaPageState();
}

class _DetailBagiHasilAnggotaPageState
    extends State<DetailBagiHasilAnggotaPage> {
  final ApiService _apiService = ApiService();

  final NumberFormat _formatter =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  List<dynamic> _dataAkad = [];
  bool _isLoading = true;

  // Variabel Header Statistik
  double _totalModalDisalurkan = 0;
  double _totalKeuntunganUsaha = 0;
  double _totalBagiHasilBMT = 0;
  double _totalBagiHasilNasabah = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- 2. LOAD DATA DARI API ---
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _totalModalDisalurkan = 0;
      _totalKeuntunganUsaha = 0;
      _totalBagiHasilBMT = 0;
      _totalBagiHasilNasabah = 0;
      _dataAkad = [];
    });

    try {
      final responseAkad = await _apiService.getMudharabah();

      if (responseAkad['status'] == true && responseAkad['data'] is List) {
        List<dynamic> allAkad = responseAkad['data'];

        List<dynamic> myAkad = allAkad
            .where((item) =>
                item['nasabah_id'].toString() == widget.nasabahId.toString())
            .toList();

        double tempModal = 0;
        double tempKeuntungan = 0;
        double tempBagiHasilBMT = 0;
        double tempBagiHasilNasabah = 0;

        for (var akad in myAkad) {
          // A. Hitung Modal Disalurkan
          String status = akad['status'] ?? '';
          if (status == 'Disetujui' || status == 'Aktif') {
            double modal = double.tryParse(akad['modal'].toString()) ??
                double.tryParse(akad['nominal_modal'].toString()) ??
                0;
            tempModal += modal;
          }

          // B. Hitung Keuntungan dari Riwayat Transaksi
          try {
            int akadId = int.parse(akad['id'].toString());
            List<dynamic> riwayat =
                await _apiService.getRiwayatBagiHasil(akadId);

            for (var tr in riwayat) {
              tempKeuntungan +=
                  double.tryParse(tr['total_keuntungan'].toString()) ?? 0;
              tempBagiHasilBMT +=
                  double.tryParse(tr['bagian_bmt'].toString()) ?? 0;
              tempBagiHasilNasabah +=
                  double.tryParse(tr['bagian_nasabah'].toString()) ?? 0;
            }
          } catch (e) {
            debugPrint("Gagal hitung riwayat akad ID ${akad['id']}");
          }
        }

        if (mounted) {
          setState(() {
            _dataAkad = myAkad;
            _totalModalDisalurkan = tempModal;
            _totalKeuntunganUsaha = tempKeuntungan;
            _totalBagiHasilBMT = tempBagiHasilBMT;
            _totalBagiHasilNasabah = tempBagiHasilNasabah;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error load bagi hasil: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 3. FUNGSI RIWAYAT TRANSAKSI ---
  void _showRiwayatTransaksi(Map<String, dynamic> akad) async {
    try {
      int akadId = int.parse(akad['id'].toString());
      final riwayat = await _apiService.getRiwayatBagiHasil(akadId);

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
                            String tgl = item['tgl_transaksi'] ?? '-';

                            double keuntunganTotal = double.tryParse(
                                    item['total_keuntungan'].toString()) ??
                                0;
                            double bagianBmt = double.tryParse(
                                    item['bagian_bmt'].toString()) ??
                                0;
                            double bagianNasabah = double.tryParse(
                                    item['bagian_nasabah'].toString()) ??
                                0;

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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal memuat riwayat transaksi")));
    }
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
                // --- HEADER SUMMARY (DIPERBARUI) ---
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
                      // 1. Modal Disalurkan
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

                      const SizedBox(height: 8),

                      // 2. Total Omzet (DIPINDAHKAN KESINI)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          "Total Omzet Usaha: ${_formatter.format(_totalKeuntunganUsaha)}",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 3. Row Pembagian (Hanya 2 Kolom Sekarang)
                      Row(
                        children: [
                          // Keuntungan Nasabah
                          Expanded(
                            child: _buildInfoBox("Keuntungan\nNasabah",
                                _totalBagiHasilNasabah, Colors.orangeAccent),
                          ),
                          const SizedBox(width: 10),

                          // Keuntungan BMT
                          Expanded(
                            child: _buildInfoBox("Bagian\nBMT",
                                _totalBagiHasilBMT, Colors.greenAccent),
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

                // --- LIST AKAD ---
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
                            String namaUsaha = item['nama_usaha'] ?? 'Usaha';
                            String status = item['status'] ?? '-';
                            double modal =
                                double.tryParse(item['modal'].toString()) ??
                                    double.tryParse(
                                        item['nominal_modal'].toString()) ??
                                    0;

                            double nisbahNasabah = double.tryParse(
                                    item['nisbah_nasabah'].toString()) ??
                                0;
                            double nisbahBmt = double.tryParse(
                                    item['nisbah_bmt'].toString()) ??
                                0;

                            Color statusColor =
                                status == 'Disetujui' || status == 'Aktif'
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
                                title: Text(namaUsaha,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text("Modal: ${_formatter.format(modal)}"),
                                    Text(
                                        "Nisbah: ${nisbahNasabah.toInt()} : ${nisbahBmt.toInt()} (N:B)"),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(status,
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

  // Helper Widget untuk Kotak Info Kecil
  Widget _buildInfoBox(String label, double nominal, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 11, height: 1.2)),
          const SizedBox(height: 5),
          Text(
            _formatter.format(nominal),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: valueColor, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
